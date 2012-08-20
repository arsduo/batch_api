module BatchApi
  # Batch API Configuration
  class Configuration
    # Public: configuration options.
    # Currently, you can set:
    # - endpoint: (URL) through which the Batch API will be exposed (default
    # "/batch)
    # - verb: through which it's accessed (default "POST")
    # - limit: how many requests can be processed in a single request
    # (default 50)
    # decode_json_responses - automatically decode JSON response bodies,
    # so they don't get double-decoded (e.g. when you decode the batch
    # response, the bodies are already objects).
    attr_accessor :verb, :endpoint, :limit
    attr_accessor :decode_json_responses
    attr_accessor :add_timestamp

    # Default values for configuration variables
    def initialize
      @verb = :post
      @endpoint = "/batch"
      @limit = 50
      @decode_json_responses = true
      @add_timestamp = true
    end
  end
end


