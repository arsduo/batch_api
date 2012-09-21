module BatchApi
  class Processor
    class Sequential
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
        env[:ops].collect do |op|
          # set the current op
          env[:op] = op

          # execute the individual request inside the operation-specific
          # middeware, then clear out the current op afterward
          middleware = InternalMiddleware.operation_stack
          middleware.call(env).tap {|r| env.delete(:op) }
        end
      end
    end
  end
end

