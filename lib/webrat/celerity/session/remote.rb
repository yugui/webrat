require 'drb/drb'
require 'timeout'
require 'tmpdir'

module Webrat #:nodoc
  module CeleritySession #:nodoc
    class Remote < Base
      def container
        self.class.boot unless self.class.boot_done?
        @_browser ||= self.class.proxy
      end


      class << self
        def proxy
          proxy = DRbObject.new_with_uri(proxy_uri)
          def proxy.method_missing(msg, *args)
            Timeout.timeout(20) {
              #puts "msg: #{msg} #{args.inspect}"
              super(msg, *args)
            }
          end
          return proxy
        end
  
        def start #:nodoc:
          dir = File.expand_path('../../core_ext', __FILE__)
          uri = proxy_uri
          @pid = fork do
            exec 'jruby', '-rubygems', '-rdrb/drb', '-e', <<-"EOS"
              gem "jarib-celerity", ">= 0.0.5"
              require "celerity"
              require "#{dir}/button.rb"
              require "#{dir}/container.rb"
              require "#{dir}/frame.rb"
              require "#{dir}/generic_field.rb"
              require "#{dir}/socket.rb"

              graceful_shutdown = proc {
                DRb.stop_service
    
                if DRb.primary_server && DRb.primary_server.alive?
                  5.times do 
                    sleep 1
                    break unless DRb.primary_server && DRb.primary_server.alive?
                    DRb.thread.kill
                  end
                end
                if DRb.primary_server && DRb.primary_server.alive?
                  Process.exit(1)
                end
              }
              Signal.trap(:TERM, &graceful_shutdown)
              Signal.trap(:INT, &graceful_shutdown)
    
              browser = Celerity::Browser.new(:browser => :firefox, :log_level => :off)
              DRb.start_service('#{uri}', browser)
              DRb.thread.join
            EOS
          end
  
          super
        end
  
        def stop_at_exit #:nodoc:
          super
          pid = @pid
          at_exit do
            catch(:done) {
              begin
                $stderr.puts "terminating #{pid}"
                Process.kill :INT, pid
                5.times do
                  if Process.waitpid(pid, Process::WNOHANG)
                    puts "Done"
                    throw :done 
                  else
                    $stderr.print "."; $stderr.flush
                    sleep 0.5
                  end
                end
                puts

                unless Process.waitpid(pid, Process::WNOHANG)
                  $stderr.puts "killing #{pid}" 
                  Process.kill :KILL, pid
                end
                Process.waitpid(pid)
              rescue Errno::ESRCH
                # nothing to do
              end
            }
          end
        end
  
        private
        def wait
          $stderr.print "==> Waiting for JRuby proxess waking up"
          wait_for_socket
          $stderr.print "Ready!\n"
        end
  
        def wait_for_socket
          Timeout.timeout(30) {
            until File.socket?(proxy_path)
              $stderr.print "."; $stderr.flush
              sleep 0.5
            end
          }
        end

        def proxy_uri
          "drbunix:#{proxy_path}"
        end

        def proxy_path
          @proxy_path ||= "#{Dir.tmpdir}/webrat-proxy.#{$$}.#{rand}"
        end
      end
    end
  end
end

