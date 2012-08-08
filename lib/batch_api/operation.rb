require 'batch_api/response'

module BatchApi
  # Public: an individual batch operation.
  class Operation
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

      # deep_dup to avoid unwanted changes across requests
      @env = base_env.deep_dup
    end

    # Public: given a URL and other operation details as specified above,
    # identify the appropriate controller to execute the action.
    #
    # This method will raise an error if the route doesn't exist.
    def identify_routing
      @path_params = Rails.application.routes.recognize_path(@url, @op)
      @controller = ActionDispatch::Routing::RouteSet::Dispatcher.new.controller(@path_params)
    end

    # Public: customize the request environment.  This is currently done
    # manually and feels clunky and brittle, but is mostly likely fine, though
    # there are one or two environment parameters not yet adjusted.
    def process_env
      path, qs = @url.split("?")

      # rails routing
      @env["action_dispatch.request.path_parameters"] = @path_param
      @env["action_controller.instance"] = @controller

      # Headers
      headrs = (@headers || {}).inject({}) do |heads, (k, v)|
        heads["HTTP_" + k.gsub(/\-/, "_").upcase] = v
      end
      # preserve original headers unless explicitly overridden
      @env.merge!(headrs)

      # method
      @env["REQUEST_METHOD"] = @method.upcase

      # path and query string
      @env["REQUEST_URI"] = @env["REQUEST_URI"].gsub(/\/batch.*/, @url)
      @env["REQUEST_PATH"] = path
      @env["ORIGINAL_FULLPATH"] = @url

      @env["PATH_INFO"] = @url
      @env["rack.request.query_string"] = qs
      @env["QUERY_STRING"] = qs

      # parameters
      @env["action_dispatch.request.parameters"] = @params
      @env["action_dispatch.request.request_parameters"] = @params
      @env["rack.request.query_hash"] = @method == "get" ? @params : nil
    end

    # Execute a batch request, returning a BatchResponse object.  If an error
    # occurs, it returns the same results as Rails would.
    def execute
      begin
        identify_routing
        process_env
        action = @controller.action(@path_param[:action])
        result = action.call(@env)
        BatchApi::Response.new(result)
      rescue => err
        puts err.class
        puts err.message
        puts err.backtrace.join("\n")
        error_response(err)
      end
    end

    # Public: create a BatchResponse for an exception thrown during batch
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
