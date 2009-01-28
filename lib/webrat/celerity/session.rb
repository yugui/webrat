require "celerity"
require "forwardable"

module Webrat #:nodoc:
  class CelerityResponse
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  class CeleritySession #:nodoc:
    extend Forwardable

    attr_reader :current_url

    def initialize(*args) # :nodoc:
    end

    def response
      CelerityResponse.new(response_body)
    end

    def response_body
      container.html
    end

    def visit(url = nil, http_method = :get, data = {})
      # TODO querify data
      @current_url = container.goto(absolute_url(url))
    end

    def click_link_within(selector, text_or_title_or_id)
      within(selector) do
        click_link(text_or_title_or_id)
      end
    end

    def current_scope
      scopes.last || base_scope
    end

    def scopes
      @_scopes ||= []
    end

    def base_scope
      @_base_scope ||= CelerityScope.from_container(container)
    end

    def within(selector)
      xpath = Webrat::XML.css_to_xpath(selector).first
      scope = CelerityScope.from_element(container.element_by_xpath(xpath))
      scopes.push(scope)
      ret = yield
      scopes.pop
      return ret
    end

    def_delegators :current_scope, :check,         :checks
    def_delegators :current_scope, :choose,        :chooses
    def_delegators :current_scope, :click_button,  :clicks_button
    def_delegators :current_scope, :click_link,    :clicks_link
    def_delegators :current_scope, :execute_script
    def_delegators :current_scope, :fill_in,       :fills_in
    def_delegators :current_scope, :field_by_xpath
    def_delegators :current_scope, :field_labeled
    def_delegators :current_scope, :field_with_id
    def_delegators :current_scope, :select,        :selects
    def_delegators :current_scope, :uncheck,       :unchecks

  protected

    def container
      return $browser if $browser
      setup
      $browser
    end

    def absolute_url(url) #:nodoc:
      if url =~ Regexp.new('^https?://')
        url
      elsif url =~ Regexp.new('^/')
        "#{current_host}#{url}"
      else
        "#{current_host}/#{url}"
      end
    end

    def current_host
      @_current_host ||= [Webrat.configuration.application_address, Webrat.configuration.application_port].join(":")
    end

    def setup #:nodoc:
      silence_stream(STDOUT) do
        Webrat.start_app_server
      end
      create_browser
      teardown_at_exit
    end

    def create_browser #:nodoc:
      $browser = ::Celerity::Browser.new(:browser => :firefox)
    end

    def teardown_at_exit #:nodoc:
      at_exit do
        silence_stream(STDOUT) do
          Webrat.stop_app_server
        end
      end
    end
  end
end
