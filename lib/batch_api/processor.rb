require 'batch_api/processor/strategies/sequential'
require 'batch_api/operation'

module BatchApi
  class Processor
    # Public: Raised when a user provides more Batch API requests than a service
    # allows.
    class OperationLimitExceeded < StandardError; end
    # Public: Raised if a provided option is invalid.
    class BadOptionError < StandardError; end
    # Public: Raised if no operations are provided.
    class NoOperationsError < ArgumentError; end

    attr_reader :ops, :options, :app

    # Public: create a new Processor.
    #
    # env - a Rack environment hash
    # app - a Rack application
    #
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    # Raises BadOptionError if other provided options are invalid.
    # Raises ArgumentError if no operations are provided (nil or []).
    #
    # Returns the new Processor instance.
    def initialize(request, app)
      @app = app
      @request = request
      @env = request.env
      @ops = self.process_ops
      @options = self.process_options

      @start_time = Time.now.to_i
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
      format_response(strategy.execute!(@ops, @options))
    end

    protected

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
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    #
    # Returns an array of BatchApi::Operation objects
    def process_ops
      ops = @request.params.delete("ops")
      if !ops || ops.empty?
        raise NoOperationsError, "No operations provided"
      elsif ops.length > BatchApi.config.limit
        raise OperationLimitExceeded,
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
    # Currently, the :sequential option is REQUIRED (until parallel
    # implementation is created).
    #
    # options - an options hash
    #
    # Returns the valid options hash.
    def process_options
      unless @request.params["sequential"]
        raise BadOptionError, "Sequential flag is currently required"
      end
      @request.params
    end
  end
end
