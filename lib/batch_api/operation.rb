require 'batch_api/response'

module BatchApi
  # Public: an individual batch operation.
  class Operation
    class MalformedOperationError < ArgumentError; end

    attr_accessor :method, :url, :params, :headers
    attr_accessor :env, :result

    # Public: create a new Batch Operation given the specifications for a batch
    # operation (as defined above) and the request environment for the main
    # batch request.
    def initialize(op, base_env)
      @op = op

      @method = op[:method]
      @url = op[:url]
      @params = op[:params]
      @headers = op[:headers]

      raise MalformedOperationError,
        "BatchAPI operation must include method (received #{@method.inspect}) " +
        "and url (received #{@url.inspect})" unless @method && @url

      # deep_dup to avoid unwanted changes across requests
      @env = base_env.deep_dup
    end

    # Execute a batch request, returning a BatchResponse object.  If an error
    # occurs, it returns the same results as Rails would.
    def execute
      begin
        action = identify_routing
        process_env
        BatchApi::Response.new(action.call(@env))
      rescue => err
        error_response(err)
      end
    end

    # Internal: given a URL and other operation details as specified above,
    # identify the appropriate controller and action to execute the action.
    #
    # Raises a routing error if the route doesn't exist.
    #
    # Returns the action object, which can be called with the environment.
    def identify_routing
      @path_params = Rails.application.routes.recognize_path(@url, @op)
      @controller = ActionDispatch::Routing::RouteSet::Dispatcher.new.controller(@path_params)
      @controller.action(@path_params[:action])
    end

    # Internal: customize the request environment.  This is currently done
    # manually and feels clunky and brittle, but is mostly likely fine, though
    # there are one or two environment parameters not yet adjusted.
    def process_env
      path, qs = @url.split("?")

      # rails routing
      @env["action_dispatch.request.path_parameters"] = @path_params
      # this isn't quite right, but hopefully it'll work
      # since we're not executing any middleware
      @env["action_controller.instance"] = @controller.new

      # Headers
      headrs = (@headers || {}).inject({}) do |heads, (k, v)|
        heads.tap {|h| h["HTTP_" + k.gsub(/\-/, "_").upcase] = v}
      end
      # preserve original headers unless explicitly overridden
      @env.merge!(headrs)

      # handle basic auth
      # Doorkeeper will accept Authorization as a key for the main request
      # but seems to fail if it's not HTTP_AUTHORIZATION in batch operations
      if @env["Authorization"] && !@env["HTTP_AUTHORIZATION"]
        @env["HTTP_AUTHORIZATION"] = @env["Authorization"]
      end

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
      wrapper = ActionDispatch::ExceptionWrapper.new(@env, err)
      BatchApi::Response.new([
        wrapper.status_code,
        {},
        BatchApi::Error.new(err)
      ])
    end
  end
end
