require 'batch_api/configuration'
require 'batch_api/version'
require 'batch_api/utils'
require 'batch_api/processor'
require 'batch_api/middleware'

module BatchApi

  # Public: access the main Batch API configuration object.
  #
  # Returns a BatchApi::Configuration instance
  def self.config
    @config ||= Configuration.new
  end

  # Public: are we in Rails?  This partly exists just so that you
  # can stub it in the tests.
  #
  # Returns true if Rails is a defined constant, false otherwise.
  def rails?
    defined?(Rails)
  end
end
