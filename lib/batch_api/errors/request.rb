require 'batch_api/errors/base'

module BatchApi
  module Errors
    # Public: This class encapsulates errors that occur at a request level.
    # For instance, it returns proper error codes for BadOptionErrors or other
    # identifiable problems.  (For actual code errors, it returns a 500
    # response.)
    class Request < BatchApi::Errors::Base

      # Public: return the appropriate status code for the error.  For
      # errors from bad Batch API input, raise a 422, otherwise, a 500.
      def status_code
        case @error
        when BatchApi::Processor::BadOptionError,
             BatchApi::Processor::OperationLimitExceeded,
             BatchApi::Processor::NoOperationsError
          422
        else
          500
        end
      end
    end
  end
end

