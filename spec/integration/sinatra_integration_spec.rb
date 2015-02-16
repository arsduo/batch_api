require 'spec_helper'
require 'support/sinatra_app'
require 'rack/test'
require_relative './shared_examples'

describe "Sinatra integration" do
  include Rack::Test::Methods

  def app
    SinatraApp
  end

  it_should_behave_like "integrating with a server", true
  it_should_behave_like "integrating with a server", false
end
