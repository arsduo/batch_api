require 'batch_api/internal_middleware/decode_json_body'

module BatchApi
  # Public: the internal middleware system used to process batch requests.
  # (Not to be confused with RackMiddleware, which handles incoming Rack
  # request.)  Based on Mitchel Hashimoto's middleware gem.
  #
  # The middleware stack is defined in a block, and has three phases:
  #   1) Global - these middlewares will be run around the entire sequence of
  #   batch requests.  Useful for global processing on a batch request; for
  #   instance, the timestamp middleware adds a timestamp based on when the
  #   original request was# started.
  #
  #   2) Processor - this automatically-provided middleware will execute all
  #   batch requests either sequentially (currently the only option) or in
  #   parallel (in the future).
  #
  #   3) Per-op - these middlewares will run once per each operation, giving
  #   you a chance to alter the results or details of an op -- for instance,
  #   decoding the body if it's JSON.
  #
  # All middlewares will receive the following as an env hash:
  #   {
  #     ops: [], # the total set of operations
  #     op: obj, # the specific operation being executed, if appropriate
  #     rack_env: {}, # the Rack environment
  #     rack_app: app # the Rack application
  #   }
  #
  # All middlewares should return the result of their individual operation or
  # the array of operation results, depending on where they are in the chain.
  module InternalMiddleware
    # Public: the default internal middlewares to be run around the entire
    # operation.
    DEFAULT_GLOBAL = Proc.new {}

    # Public: the default internal middlewares to be run around each batch
    # operation.
    DEFAULT_PER_OP = Proc.new do
      # Decode JSON response bodies, so they're not double-encoded.
      use BatchApi::InternalMiddleware::DecodeJsonBody
    end

    # Public: the middleware stack to use for requests.
    def self.stack
      Middleware::Builder.new do
        puts "building the block"
        puts self.inspect
        # evaluate these in the context of the middleware object
        self.instance_eval &BatchApi.config.global_middleware
        # for now, everything's sequential, but that will change
        use BatchApi::Processor::Sequential
        self.instance_eval &BatchApi.config.per_op_middleware
      end
    end
  end
end
