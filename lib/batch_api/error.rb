module BatchApi
  # Public: an error thrown during a batch operation.
  # This has a body class and a cookies accessor and can
  # function in place of a regular BatchResponse object.
  class Error
    # Public: create a new BatchError from a Rails error.
    def initialize(error)
      @message = error.message
      @backtrace = error.backtrace
    end

    # Public: the error details as a hash, which can be returned
    # to clients as JSON.
    def body
      message = if expose_backtrace?
        {
          message: @message,
          backtrace: @backtrace
        }
      else
        { message: @message }
      end
      { error: message }
    end

    # Public: turn the error body into a Rack-compatible body component.
    #
    # Returns: an Array with the error body represented as JSON.
    def render
      [MultiJson.dump(body)]
    end

    # Internal: whether the backtrace should be exposed in the response.
    # Currently Rails-specific, needs to be generalized (to ENV["RACK_ENV"])?
    def expose_backtrace?
      Rails.env.production?
    end
  end
end
