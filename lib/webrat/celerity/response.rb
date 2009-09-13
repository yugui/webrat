module Webrat #:nodoc:
  class CelerityResponse
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end
end
