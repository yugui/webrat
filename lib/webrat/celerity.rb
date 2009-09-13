require "webrat/celerity/session"
require "webrat/celerity/locator"

module Webrat
  # To use Webrat's Celerity support, activate it with (for example, in your <tt>env.rb</tt>):
  #
  #   require "webrat"
  #
  #   Webrat.configure do |config|
  #     config.mode = :celerity
  #   end
  #
  # == Auto-starting of the mongrel server
  #
  # Webrat will automatically start an instance of Mongrel when a test is run. The Mongrel will
  # run in the "celerity" environment instead of "test", so ensure you've got that defined, and
  # will run on port 3001.
  module Celerity
    module Methods
      def response
        webrat_session.response
      end

      def execute_script(source)
        webrat_session.execute_script(source)
      end

      def clear_cookies
        webrat_session.clear_cookies
      end

      def within_frame(name, &block)
        webrat_session.within_frame(name, &block)
      end
    end
  end
end
