require 'batch_api/processor/sequential'
require 'batch_api/operation'

module BatchApi
  class Processor
    attr_reader :ops, :options, :app

    # Public: create a new Processor.
    #
    # env - a Rack environment hash
    # app - a Rack application
    #
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    # Raises Errors::BadOptionError if other provided options are invalid.
    # Raises ArgumentError if no operations are provided (nil or []).
    #
    # Returns the new Processor instance.
    def initialize(request, app)
      @app = app
      @request = request
      @env = request.env
      @ops = self.process_ops
      @options = self.process_options
    end

    # Public: the processing strategy to use, based on the options
    # provided in BatchApi setup and the request.
    # Currently only Sequential is supported.
    def strategy
      @request.params["sequential"] ? BatchApi::Processor::Sequential : BatchApi::Processor::Parallel
    end

    # Public: run the batch operations according to the appropriate strategy.
    #
    # Returns a set of BatchResponses
    def execute!
      stack = InternalMiddleware.batch_stack(self)
      format_response(stack.call(middleware_env))
    end

    protected

    def middleware_env
      {
        ops: @ops,
        rack_env: @env,
        rack_app: @app,
        options: @options
      }
    end

    # Internal: format the result of the operations, and include
    # any other appropriate information (such as timestamp).
    #
    # result - the array of batch operations
    #
    # Returns a hash ready to go to the user
    def format_response(operation_results)
      {
        "results" => operation_results
      }
    end

    # Internal: Validate that an allowable number of operations have been
    # provided, and turn them into BatchApi::Operation objects.
    #
    # ops - a series of operations
    #
    # Raises Errors::OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    # Raises Errors::NoOperationsError if no operations are provided.
    #
    # Returns an array of BatchApi::Operation objects
    def process_ops
      ops = @request.params.delete("ops")
      if !ops || ops.empty?
        raise Errors::NoOperationsError, "No operations provided"
      elsif ops.length > BatchApi.config.limit
        raise Errors::OperationLimitExceeded,
          "Only #{BatchApi.config.limit} operations can be submitted at once, " +
          "#{ops.length} were provided"
      else
        ops.map do |op|
          self.class.operation_klass.new(op, @env, @app)
        end
      end
    end

    # Internal: which operation class to used.
    #
    # Returns Batch::Operation::(Rack|Rails) depending on the environment
    def self.operation_klass
      BatchApi.rails? ? Operation::Rails : Operation::Rack
    end

    # Internal: Processes any other provided options for validity.
    #
    # options - an options hash
    #
    # Returns the valid options hash.
    def process_options
      @request.params
    end
  end
end
