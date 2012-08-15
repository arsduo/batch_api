module BatchApi
  class Middleware
    def initialize(app, &block)
      @app = app

      yield BatchApi.config if block
    end

    def call(env)
      if batch_request?(env)
        result = BatchApi::Processor.new(env, @app).execute!
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
  end
end
