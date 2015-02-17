require 'middleware'
require 'batch_api/processor/sequential'
require 'batch_api/processor/parallel'
require 'batch_api/processor/executor'
require 'batch_api/internal_middleware/decode_json_body'
require 'batch_api/internal_middleware/response_filter'

module BatchApi
  # Public: the internal middleware system used to process batch requests.
  # (Not to be confused with RackMiddleware, which handles incoming Rack
  # request.)  Based on Mitchel Hashimoto's middleware gem.
  #
  # There are actually two internal middleware stacks, one run around the
  # entire request and the other run around each individual operation.
  #
  # The batch_middleware stack consists of two parts:
  #   1) Custom middlewares - these middlewares will be run around the entire
  #   sequence of batch requests.  Useful for global processing on a batch
  #   request; for instance, the timestamp middleware adds a timestamp based on
  #   when the original request was started.  This should return an array of
  #   BatchApi::Response objects.
  #
  #   2) Processor - this automatically-provided middleware will execute all
  #   batch requests either sequentially (currently the only option) or in
  #   parallel (in the future).  This will return an array of
  #   BatchApi::Response objects.
  #
  # The operation_middleware stack also consists of two parts:
  #   1) Operation - these middlewares will run once per each operation, giving
  #   you a chance to alter the results or details of an op -- for instance,
  #   decoding the body if it's JSON.  This should return an individual
  #   BatchApi::Response object.
  #
  #   2) Executor - this automatically-provided middleware actually executes
  #   the individual Rack request, and returns a BatchApi::Response object.
  #
  # Symetry, right?
  #
  # All middlewares#call will receive the following as an env hash:
  #   {
  #     # for batch middlewares
  #     ops: [], # the total set of operations
  #     # for operation middlewares
  #     op: obj, # the specific operation being executed
  #     # all middlewares get the following:
  #     rack_env: {}, # the Rack environment
  #     rack_app: app # the Rack application
  #   }
  #
  # All middlewares should return the result of their individual operation or
  # the array of operation results, depending on where they are in the chain.
  # (See above.)
  module InternalMiddleware
    # Public: the default internal middlewares to be run around the entire
    # operation.
    DEFAULT_BATCH_MIDDLEWARE = Proc.new {}

    # Public: the default internal middlewares to be run around each batch
    # operation.
    DEFAULT_OPERATION_MIDDLEWARE = Proc.new do
      # Decode JSON response bodies, so they're not double-encoded.
      use InternalMiddleware::ResponseFilter
      use InternalMiddleware::DecodeJsonBody
    end

    # Public: the middleware stack to use for processing the batch request as a
    # whole..
    def self.batch_stack(processor)
      Middleware::Builder.new do
        # evaluate these in the context of the middleware stack
        self.instance_eval &BatchApi.config.batch_middleware
        use processor.strategy
      end
    end
    #
    # Public: the middleware stack to use for processing each batch operation.
    def self.operation_stack
      Middleware::Builder.new do
        # evaluate the operation middleware in the context of the middleware
        # stack
        self.instance_eval &BatchApi.config.operation_middleware
        # and end with actually executing the batch request
        use Processor::Executor
      end
    end
  end
end
