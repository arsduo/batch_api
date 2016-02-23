module BatchApi
  # Public: wrap an error thrown during a batch operation.
  # This has a body class and a cookies accessor and can
  # function in place of a regular BatchResponse object.
  class ErrorWrapper
    # Public: create a new ErrorWrapper from an error object.
    def initialize(error)
      @error = error
      @status_code = error.status_code if error.respond_to?(:status_code)
    end

    # Public: the error details as a hash, which can be returned
    # to clients as JSON.
    def body
      message = if self.class.expose_backtrace?
        {
          message: @error.message,
          backtrace: @error.backtrace
        }
      else
        { message: @error.message }
      end
      { error: message }
    end

    # Public: turn the error body into a Rack-compatible body component.
    #
    # Returns: an Array with the error body represented as JSON.
    def render
      [status_code, RackMiddleware.content_type, [body.to_json]]
    end

    # Public: the status code to return for the given error.
    def status_code
      @status_code || 500
    end

    # Internal: whether the backtrace should be exposed in the response.
    # Currently Rails-specific, needs to be generalized (to ENV["RACK_ENV"])?
    def self.expose_backtrace?
      !Rails.env.production?
    end
  end
end
