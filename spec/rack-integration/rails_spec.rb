require 'spec_helper'
require_relative './shared_examples'

describe "Rails integration specs", type: :request do
  before :each do
    BatchApi.stub(:rails?).and_return(true)
  end

  it_should_behave_like "integrating with a server"
end
