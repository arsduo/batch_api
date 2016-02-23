module BatchApi
  class RackMiddleware
    def initialize(app, &block)
      @app = app
      yield BatchApi.config if block
    end

    def call(env)
      if batch_request?(env)
        begin
          request = request_klass.new(env)
          result = BatchApi::Processor.new(request, @app).execute!
          [200, self.class.content_type, [result.to_json]]
        rescue => err
          ErrorWrapper.new(err).render
        end
      else
        @app.call(env)
      end
    end

    def self.content_type
      {"Content-Type" => "application/json"}
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
