require 'spec_helper'
require 'support/sinatra_app'
require 'rack/test'
require_relative './shared_examples'

describe "Sinatra integration" do
  include Rack::Test::Methods

  def app
    SinatraApp
  end

  # for compatibility with the Rails specs, which expect response
  def response
    last_response
  end

  it_should_behave_like "integrating with a server"
end
