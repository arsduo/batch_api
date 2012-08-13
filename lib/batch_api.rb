require 'batch_api/routing_helper'
require 'batch_api/engine'
require 'batch_api/configuration'
require 'batch_api/version'
require 'batch_api/processor'

module BatchApi
  mattr_accessor :config
  def self.config
    @@config || Configuration.new
  end

  def self.setup
    yield (self.config = Configuration.new)
  end
end
