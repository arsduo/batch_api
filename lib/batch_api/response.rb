require 'batch_api/error'

module BatchApi
  # Public: a response from an internal operation in the Batch API.
  # It contains all the details that are needed to describe the call's
  # outcome.
  class Response
    # Public: the attributes of the HTTP response.
    attr_accessor :status, :body, :headers, :cookies

    # Public: create a new response representation from a Rack-compatible
    # response (e.g. [status, headers, response_object]).
    def initialize(response)
      @status = response.first
      @headers = response[1]

      response_object = response[2]
      puts response.inspect if response_object.nil?
      @body = response_object.body
      @cookies = response_object.cookies
      puts self.to_json
    end
  end
end

