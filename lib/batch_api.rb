require 'batch_api/configuration'
require 'batch_api/version'
require 'batch_api/utils'
require 'batch_api/processor'
require 'batch_api/middleware'

module BatchApi
  def self.config
    @config ||= Configuration.new
  end
end
