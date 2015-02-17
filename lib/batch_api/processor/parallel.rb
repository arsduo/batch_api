require 'batch_api/parallel_actor'
module BatchApi
  class Processor
    class Parallel
      
      # Public: initialize with the app.
      def initialize(app)
        @app = app
      end

      # Public: execute all operations sequentially.
      #
      # ops - a set of BatchApi::Operations
      # options - a set of options
      #
      # Returns an array of BatchApi::Response objects.
      def call(env)
        futures = env[:ops].map do |op|
          _env = BatchApi::Utils.deep_dup(env)
          _env[:op] = op
          self.class.get_actor_pool.future.run(_env)
        end
        futures.map do |future|
          future.value
        end
      end
      
      def self.get_actor_pool
        Celluloid::Actor[:batch_parallel_pool] ||= BatchApi::ParallelActor.pool(size: BatchApi.config.parallel_size)
      end
    end
  end
end

