module BatchApi
  module InternalMiddleware
    # Public: a middleware that decodes the body of any individual batch
    # operation if the it's JSON.
    class DecodeJsonBody
      # Public: initialize the middleware.
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).tap do |result|
          if should_decode?(result) && result.body.present?
            result.body = MultiJson.load(result.body)
          end
        end
      end

      private

      def should_decode?(result)
        result.headers["Content-Type"] =~ /^application\/json/
      end
    end
  end
end
