module BatchApi
  module Errors
    # Public: a StandardError class that can be used with the Batch API.  Has
    # built-in support for custom status codes.
    class BatchError < StandardError
      # Public: the status code for this type of error.
      # Subclasses can change this as desired.
      def status_code; 500; end
    end

    # Public: an error thrown if an invalid option is
    # specificed.
    class BadOptionError < BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if too many operations are provided.
    class OperationLimitExceeded < BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if no operations are provided.
    class NoOperationsError < BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if one of the batch operations
    # is somehow invalid (missing key parameters, etc.).
    class MalformedOperationError < BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end
  end
end