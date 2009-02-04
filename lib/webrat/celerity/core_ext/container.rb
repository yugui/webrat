module Celerity
  module Container
    # Used internally to update the page object.
    # @api private
    def update_page(page)
      @browser.page = page unless page.web_response.content_type == "application/json"
    end
  end
end
