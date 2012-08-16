module BatchApi
  class Processor
    module Strategies
      module Sequential
        # Public: execute all operations sequentially.
        #
        # ops - a set of BatchApi::Operations
        # options - a set of options
        #
        # Returns an array of BatchApi::Response objects.
        def self.execute!(ops, options = {})
          ops.map(&:execute)
        end
      end
    end
  end
end

