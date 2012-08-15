require 'batch_api/processor/strategies/sequential'
require 'batch_api/operation'

module BatchApi
  class Processor
    # Raised when a user provides more Batch API requests than a service
    # allows.
    class OperationLimitExceeded < StandardError; end
    # Raised if a provided option is invalid.
    class BadOptionError < StandardError; end

    attr_reader :ops, :options, :app

    # Public: create a new Processor.
    #
    # ops - an array of operations hashes
    # options - any other options
    #
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    # Raises BadOptionError if other provided options are invalid.
    # Raises ArgumentError if no operations are provided (nil or []).
    #
    # Returns the new Processor instance.
    def initialize(env, app)
      @app = app
      @env = env
      @ops = self.process_ops
      @options = self.process_options
    end

    # Public: the processing strategy to use, based on the options
    # provided in BatchApi setup and the request.
    # Currently only Sequential is supported.
    def strategy
      BatchApi::Processor::Strategies::Sequential
    end

    # Public: run the batch operations according to the appropriate strategy.
    #
    # Returns a set of BatchResponses
    def execute!
      strategy.execute!(@ops, @options)
    end

    protected

    # Internal: Validate that an allowable number of operations have been
    # provided, and turn them into BatchApi::Operation objects.
    #
    # ops - a series of operations
    #
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    #
    # Returns an array of BatchApi::Operation objects
    def process_ops
      ops = params.delete("ops")
      if !ops || ops.empty?
        raise ArgumentError, "No operations provided"
      elsif ops.length > BatchApi.config.limit
        raise OperationLimitExceeded,
          "Only #{BatchApi.config.limit} operations can be submitted at once, " +
          "#{ops.length} were provided"
      else
        ops.map do |op|
          BatchApi::Operation.new(op, @env, @app)
        end
      end
    end

    # Internal: Processes any other provided options for validity.
    # Currently, the :sequential option is REQUIRED (until parallel
    # implementation is created).
    #
    # options - an options hash
    #
    # Returns the valid options hash.
    def process_options
      raise BadOptionError, "Sequential flag is currently required" unless params["sequential"]
      params
    end

    # Internal: a convenience method to the parameters hash provided by
    # Rack.
    def params
      @env["action_dispatch.request.request_parameters"]
    end
  end
end
