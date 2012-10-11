module BatchApi
  module Errors
    # Public: a module that tags Batch API errors and provides a default
    # status.
    module BatchError
      # Public: the status code for this type of error.
      # Subclasses can change this as desired.
      def status_code; 500; end
    end

    # Public: an error thrown if an invalid option is
    # specificed.
    class BadOptionError < ArgumentError
      include BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if too many operations are provided.
    class OperationLimitExceeded < ArgumentError
      include BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if no operations are provided.
    class NoOperationsError < ArgumentError
      include BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end

    # Public: an error thrown if one of the batch operations
    # is somehow invalid (missing key parameters, etc.).
    class MalformedOperationError < ArgumentError
      include BatchError
      # Public: the status code for this error.
      def status_code; 422; end
    end
  end
end