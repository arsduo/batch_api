module BatchApi
  module RoutingHelper
    DEFAULT_VERB = :post
    DEFAULT_ENDPOINT = "/batch"
    DEFAULT_TARGET = "batch_api/batch#batch"

    def batch_api(options = {})
      endpoint = options.delete(:endpoint) || DEFAULT_ENDPOINT
      verb = options.delete(:via) || DEFAULT_VERB
      target = options.delete(:target) || DEFAULT_TARGET
      match({endpoint => target, via: verb}.merge(options))
    end
  end
end
