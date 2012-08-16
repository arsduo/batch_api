require 'batch_api/error'

module BatchApi
  # Public: a response from an internal operation in the Batch API.
  # It contains all the details that are needed to describe the call's
  # outcome.
  class Response
    # Public: the attributes of the HTTP response.
    attr_accessor :status, :body, :headers

    # Public: create a new response representation from a Rack-compatible
    # response (e.g. [status, headers, response_object]).
    def initialize(response)
      @status, @headers = *response
      # bodies have to respond to .each, but may otherwise
      # not be suitable for JSON serialization
      # (I'm looking at you, ActionDispatch::Response)
      # so turn it into a string
      @body = ""
      response[2].each {|str| @body << str}
    end
  end
end

