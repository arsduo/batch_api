require 'batch_api/response'

module BatchApi
  # Public: an individual batch operation.
  class Operation
    class MalformedOperationError < ArgumentError; end

    attr_accessor :method, :url, :params, :headers
    attr_accessor :env, :app, :result

    # Public: create a new Batch Operation given the specifications for a batch
    # operation (as defined above) and the request environment for the main
    # batch request.
    def initialize(op, base_env, app)
      @op = op

      @method = op[:method]
      @url = op[:url]
      @params = op[:params]
      @headers = op[:headers]

      raise MalformedOperationError,
        "BatchAPI operation must include method (received #{@method.inspect}) " +
        "and url (received #{@url.inspect})" unless @method && @url

      @app = app
      # deep_dup to avoid unwanted changes across requests
      @env = BatchApi::Utils.deep_dup(base_env)
    end

    # Execute a batch request, returning a BatchResponse object.  If an error
    # occurs, it returns the same results as Rails would.
    def execute
      begin
        process_env
        BatchApi::Response.new(@app.call(@env))
      rescue => err
        error_response(err)
      end
    end

    # Internal: customize the request environment.  This is currently done
    # manually and feels clunky and brittle, but is mostly likely fine, though
    # there are one or two environment parameters not yet adjusted.
    def process_env
      path, qs = @url.split("?")

      # Headers
      headrs = (@headers || {}).inject({}) do |heads, (k, v)|
        heads.tap {|h| h["HTTP_" + k.gsub(/\-/, "_").upcase] = v}
      end
      # preserve original headers unless explicitly overridden
      @env.merge!(headrs)

      # method
      @env["REQUEST_METHOD"] = @method.upcase

      # path and query string
      @env["REQUEST_URI"] = @env["REQUEST_URI"].gsub(/\/batch.*/, @url)
      @env["REQUEST_PATH"] = path
      @env["ORIGINAL_FULLPATH"] = @env["PATH_INFO"] = @url

      @env["rack.request.query_string"] = @env["QUERY_STRING"] = qs

      # parameters
      @env["action_dispatch.request.parameters"] = @params
      @env["action_dispatch.request.request_parameters"] = @params
      @env["rack.request.query_hash"] = @method == "get" ? @params : nil
    end

    # Internal: create a BatchResponse for an exception thrown during batch
    # processing.
    def error_response(err)
      BatchApi::Response.new([
        500,
        {},
        BatchApi::Error.new(err).render
      ])
    end
  end
end
