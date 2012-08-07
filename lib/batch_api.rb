require 'batch_api/configuration'
require 'batch_api/version'
require 'active_support/dependencies'

module BatchApi
  mattr_accessor :config

  def self.setup
    yield (self.config = Configuration.new)
  end
end
