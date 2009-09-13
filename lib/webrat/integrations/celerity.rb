require 'webrat/celerity'

if defined?(ActionController)
  module ActionController #:nodoc:
    IntegrationTest.class_eval do
      include Webrat::Methods
      include Webrat::Matchers
      include Webrat::HaveTagMatcher
      include Webrat::Celerity::Methods
    end
  end
end
