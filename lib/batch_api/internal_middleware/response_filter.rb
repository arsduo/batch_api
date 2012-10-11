module BatchApi
  module InternalMiddleware
    # Public: a batch middleware which surpresses the response from a call.  If you
    # know you don't need a response (for instance, for a POST or PUT), you can
    # add silent: true (or any truthy value, like 1) to your operation to
    # surpress all output for successful requests.  Failed requests (status !=
    # 2xx) will still return information.
    class ResponseFilter
      # Public: init the middleware.
      def initialize(app)
        @app = app
      end

      # Public: execute the call.  If env[:op].options[:silent] is true, it'll
      # remove any output for a successful response.
      def call(env)
        @app.call(env).tap do |result|
          if env[:op].options["silent"] && (200...299).include?(result.status)
            # we have success and a request for silence
            # so remove all the content before proceeding
            result.status = result.body = result.headers = nil
          end
        end
      end
    end
  end
end
