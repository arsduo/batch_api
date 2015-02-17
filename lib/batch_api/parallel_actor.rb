require 'celluloid'

module BatchApi
  class ParallelActor
    include ::Celluloid
    
    def run(env)
      middleware = InternalMiddleware.operation_stack

      if defined?(ActiveRecord)
        ActiveRecord::Base.connection_pool.with_connection do
          middleware.call(env).tap {|r| env.delete(:op) }
        end
      else
        middleware.call(env).tap {|r| env.delete(:op) }
      end
    end
  end
end

  