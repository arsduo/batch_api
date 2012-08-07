module BatchApi
  # Batch API Configuration
  class Configuration
    # Public: configuration options.
    # Currently, you can set endpoint (URL) to expose the Batch API
    # under (default "/batch"), and via which HTTP verb (default "POST").
    attr_accessor :verb, :endpoint

    # Default values for configuration variables
    def initialize
      @verb = :post
      @endpoint = "/batch"
    end
  end
end
