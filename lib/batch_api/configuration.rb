module BatchApi
  # Batch API Configuration
  class Configuration
    # Public: configuration options.
    # Currently, you can set:
    # - endpoint: (URL) through which the Batch API will be exposed (default
    # "/batch)
    # - verb: through which it's accessed (default "POST")
    # - limit: how many requests can be processed in a single request
    attr_accessor :verb, :endpoint, :limit

    # Default values for configuration variables
    def initialize
      @verb = :post
      @endpoint = "/batch"
      @limit = 20
    end
  end
end


