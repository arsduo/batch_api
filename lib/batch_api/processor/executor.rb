module BatchApi
  class Processor
    # Public: a simple middleware that lives at the end of the internal chain
    # and simply executes each batch operation.
    class Executor

      # Public: initialize the middleware.
      def initialize(app)
        @app = app
      end

      # Public: execute the batch operation.
      def call(env)
        env[:op].execute
      end
    end
  end
end
