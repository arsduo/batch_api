require 'batch_api/processor/strategies/sequential'

module BatchApi
  class Processor
    # Raised when a user provides more Batch API requests than a service
    # allows.
    class OperationLimitExceeded < StandardError; end
    # Raised if a provided option is invalid.
    class BadOptionError < StandardError; end

    attr_reader :ops, :options

    # Public: create a new Processor.
    #
    # ops - an array of operations hashes
    # options - any other options
    #
    # Raises OperationLimitExceeded if more operations are requested than
    # allowed by the BatchApi configuration.
    # Raises BadOptionError if other provided options are invalid.
    #
    # Returns the new Processor instance.
    def initialize(ops, env, options = {})
      @env = env
      @options = self.process_options(options)
      @ops = self.process_ops(ops)
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
    def process_ops(ops)
      if ops.length > BatchApi.config.limit
        raise OperationLimitExceeded,
          "Only #{BatchApi.config.limit} operations can be submitted at once, " +
          "#{ops.length} were provided"
      else
        ops.map do |op|
          BatchApi::Operation.new(op, @env)
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
    def process_options(options)
      raise BadOptionError, "Sequential flag is currently required" unless options[:sequential]
      options
    end
  end
end
