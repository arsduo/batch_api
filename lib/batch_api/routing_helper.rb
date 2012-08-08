module BatchApi
  module RoutingHelper
    DEFAULT_VERB = :post
    DEFAULT_ENDPOINT = "/batch"

    def batch_api(options = {})
      endpoint = options.delete(:endpoint) || DEFAULT_ENDPOINT
      verb = options.delete(:verb) || DEFAULT_VERB
      match({endpoint => "batch#batch", via: verb}.merge(options))
    end
  end
end
