module BatchApi
  class Processor
    class Semiparallel
      # Public: initialize with the app.
      def initialize(app)
        @app = app
      end

      # Public: execute all operations sequentially.
      #
      # ops - a set of BatchApi::Operations
      # options - a set of options
      #
      # Returns an array of BatchApi::Response objects.
      def call(env)
        ops = env[:ops].chunk do |op|
          op.method == "get"
        end.map do |is_get, operations|
          if is_get && operations.length > 1
            ParallelOps.new(operations)
          else
            operations
          end
        end.flatten

        ops.collect do |op|
          if op.is_a?(ParallelOps)
            op.process(env)
          else
            # set the current op
            env[:op] = op

            # execute the individual request inside the operation-specific
            # middeware, then clear out the current op afterward
            middleware = InternalMiddleware.operation_stack
            middleware.call(env).tap {|r| env.delete(:op) }
          end
        end.flatten
      end

      private

      # Internal: Represents a collection of operations that can be safely
      # executed in parallel.
      #
      # ops - the array of operations that may be executd in parallel.
      class ParallelOps < Struct.new(:ops)
        # Public: Processes the collection of parallelizable operations in a
        # thread.
        #
        # NOTE: If we saw that the overhead is too big, we may use a thread pool
        # instead.
        #
        # Returns an ordered collection of results.
        def process(env)
          ops.map do |op|
            Thread.new do
              dupped      = env.deep_dup
              dupped[:op] = op

              middleware = InternalMiddleware.operation_stack
              middleware.call(dupped)
            end
          end.map(&:join).map(&:value)
        end
      end
    end
  end
end

