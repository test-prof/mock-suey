# frozen_string_literal: true

module MockSuey
  module RSpec
  end
end

require "mock_suey/rspec/proxy_method_invoked"
require "mock_suey/rspec/mock_context"

RSpec.configure do |config|
  config.before(:suite) do
    MockSuey.cook
  end

  config.after(:suite) do
    MockSuey.eat
  end
end
