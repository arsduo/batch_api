require 'spec_helper'
require_relative './shared_examples'

describe "Rails integration specs" do
  before :each do
    BatchApi.stub(:rails?).and_return(true)
  end

  it_should_behave_like "integrating with a server", true
  it_should_behave_like "integrating with a server", false
end
