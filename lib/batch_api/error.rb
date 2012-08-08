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

    # Public: here for compatibility with BatchResponse interface.
    attr_reader :cookies

    # Public: the error details as a hash, which can be returned
    # to clients as JSON.
    def body
      unless Rails.env.production?
        {
          message: @message,
          backtrace: @backtrace
        }
      else
        { message: @message }
      end
    end
  end
end
