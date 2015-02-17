require 'batch_api/internal_middleware'

module BatchApi
  # Public: configuration options.
  # Currently, you can set:
  # - endpoint: (URL) through which the Batch API will be exposed (default
  # "/batch)
  # - verb: through which it's accessed (default "POST")
  # - limit: how many requests can be processed in a single request
  # (default 50)
  #
  # There are also two middleware-related options -- check out middleware.rb
  # for more information.
  # - global_middleware: any middlewares to use round the entire batch request
  # (such as authentication, etc.)
  # - per_op_middleware: any middlewares to run around each individual request
  # (adding headers, decoding JSON, etc.)
  CONFIGURATION_OPTIONS = {
    verb: :post,
    endpoint: "/batch",
    limit: 50,
    parallel_size: 10,
    batch_middleware: InternalMiddleware::DEFAULT_BATCH_MIDDLEWARE,
    operation_middleware: InternalMiddleware::DEFAULT_OPERATION_MIDDLEWARE
  }

  # Batch API Configuration
  class Configuration < Struct.new(*CONFIGURATION_OPTIONS.keys)
    # Public: initialize a new configuration option and apply the defaults.
    def initialize
      super
      CONFIGURATION_OPTIONS.each {|k, v| self[k] = v}
    end
  end
end


