# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'rspec/rails'
require 'faker'
require 'timecop'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

RSpec.configure do |config|
  config.before :each do
    BatchApi.config.limit = 20
    BatchApi.config.parallel_size = 11
    BatchApi.config.endpoint = "/batch"
    BatchApi.config.verb = :post

    BatchApi.stub(:rails?).and_return(false)
  end
end
