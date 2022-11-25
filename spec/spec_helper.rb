# frozen_string_literal: true

begin
  require "debug" unless ENV["CI"] == "true"
rescue LoadError
end

require "ruby-next/language/runtime"

if ENV["CI"] == "true"
  # Only transpile specs, source code MUST be loaded from pre-transpiled files
  RubyNext::Language.watch_dirs.clear
  RubyNext::Language.watch_dirs << __dir__
end

require "mock-suey"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

# Preload fixture classes
Dir["#{File.dirname(__FILE__)}/fixtures/shared/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.define_derived_metadata(file_path: %r{/spec/cases/}) do |metadata|
    metadata[:type] = :integration
  end

  config.include IntegrationHelpers, type: :integration

  config.order = :random
  Kernel.srand config.seed
end
