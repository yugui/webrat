require 'drb/drb'
require 'timeout'

module Webrat #:nodoc
  module CeleritySession #:nodoc
    class Remote < Base
      def container
        self.class.boot unless self.class.boot_done?
        @_browser ||= self.class.proxy
      end


      class << self
        def proxy
          DRbObject.new_with_uri("druby://#{proxy_address}:#{proxy_port}")
        end
  
        def start #:nodoc:
          dir = File.expand_path('../../core_ext', __FILE__)
          @pid = fork do
            exec 'jruby', '-rubygems', '-rdrb/drb', '-e', <<-"EOS"
              gem "jarib-celerity", ">= 0.0.5"
              require "celerity"
              require "#{dir}/button.rb"
              require "#{dir}/container.rb"
              require "#{dir}/frame.rb"
              require "#{dir}/generic_field.rb"
              require "#{dir}/socket.rb"
              Signal::trap(:TERM) {
                DRb.stop_service
    
                if DRb.alive?
                  5.times do 
                    sleep 1
                    break unless DRb.alive?
                    DRb.thread.kill
                  end
                end
                if DRb.alive?
                  Process.exit(1)
                end
              }
              Signal::trap(:INT){}
    
              browser = Celerity::Browser.new(:browser => :firefox, :log_level => :off)
              DRb.start_service('druby://#{proxy_address}:#{proxy_port}', browser)
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
                Process.kill :TERM, pid
                5.times do
                  throw :done if Process.waitpid(pid, Process::WNOHANG)
                  sleep 0.5
                end
                Process.kill :KILL, pid
              rescue Errno::ESRCH
                # nothing to do
              end
            }
          end
        end
  
        private
        def wait
          $stderr.print "==> Waiting for #{proxy_address} application server on port #{proxy_port}..."
          wait_for_socket
          $stderr.print "Ready!\n"
        end
  
        def wait_for_socket
          Timeout.timeout(30) {
            begin
              sock = TCPSocket.open(proxy_address, proxy_port)
              sock.close unless sock.nil?
            rescue Errno::ECONNREFUSED, Errno::EBADF
              $stderr.print ".";
              $stderr.flush
              sleep 2
              retry
            end
          }
        end

        def proxy_address
          Webrat.configuration.celerity_proxy_address || 'localhost'
        end
  
        def proxy_port
          Webrat.configuration.celerity_proxy_port || 5555
        end
  
      end
    end
  end
end

