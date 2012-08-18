require 'spec_helper'
require_relative './shared_examples'

describe "Rails integration specs" do
  it_should_behave_like "integrating with a server"
end
