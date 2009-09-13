gem "jarib-celerity", ">= 0.0.5"
require "celerity"
require "webrat/celerity/core_ext/button"
require "webrat/celerity/core_ext/container"
require "webrat/celerity/core_ext/frame"
require "webrat/celerity/core_ext/generic_field"
require "webrat/celerity/core_ext/socket"

module Webrat #:nodoc
  module CeleritySession #:nodoc
    class Local < Base #:nodoc
      def container
        self.class.boot unless self.class.boot_done?
        @_browser ||= ::Celerity::Browser.new(:browser => :firefox, :log_level => :off)
      end
    end
  end
end
