require 'batch_api/errors/base'

module BatchApi
  module Errors
    # Public: This class encapsulates errors that occur at a request level.
    # For instance, it returns proper error codes for BadOptionErrors or other
    # identifiable problems.  (For actual code errors, it returns a 500
    # response.)
    class Request < BatchApi::Errors::Base
      def status_code
        case @error.class
        when BadOptionErrors, OperationLimitExceeded, NoOperationsError
          422
        end
      end
    end
  end
end

