# frozen_string_literal: true

require "mock_suey"

MockSuey.configure do |config|
  config.debug = true
  config.store_mocked_calls = ENV["STORE_MOCKS"] == "true"
  config.type_check = :ruby if ENV["TYPED_DOUBLE"] == "true"
  config.type_check = :sorbet if ENV["TYPED_SORBET"] == "true"
  config.signature_load_dirs = ENV["RBS_SIG_PATH"]
  config.auto_type_check = ENV["AUTO_TYPE_CHECK"] == "true"
  config.verify_mock_contracts = ENV["VERIFY_CONTRACTS"] == "true"
  config.trace_real_calls_via = ENV.fetch("TRACE_VIA", "prepend").to_sym
end

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
