module BatchApi
  class Middleware
    def initialize(app, &block)
      @app = app

      yield BatchApi.config if block
    end

    def call(env)
      if batch_request?(env)
        request = request_klass.new(env)
        result = BatchApi::Processor.new(request, @app).execute!
        [200, {"Content-Type" => "application/json"}, [MultiJson.dump(result)]]
      else
        @app.call(env)
      end
    end

    private

    def batch_request?(env)
      env["PATH_INFO"] == BatchApi.config.endpoint &&
        env["REQUEST_METHOD"] == BatchApi.config.verb.to_s.upcase
    end

    def request_klass
      defined?(ActionDispatch) ? ActionDispatch::Request : Rack::Request
    end
  end
end
