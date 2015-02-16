require 'celluloid'

module BatchApi
  class ParallelActor
    include ::Celluloid
    
    def run(env)
      middleware = InternalMiddleware.operation_stack
      middleware.call(env).tap {|r| env.delete(:op) }
    end
  end
end

  