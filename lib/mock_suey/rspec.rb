# frozen_string_literal: true

module MockSuey
  module RSpec
    module_function

    def register_example_failure(example, err)
      example.execution_result.status = :failed
      example.execution_result.exception = err
      example.set_aggregate_failures_exception(err)
    end

    def report_non_example_failure(err, location = nil)
      err.set_backtrace([location]) if err.backtrace.nil? && location

      ::RSpec.configuration.reporter.notify_non_example_exception(
        err,
        "An error occurred after suite run."
      )
    end
  end
end

require "mock_suey/rspec/proxy_method_invoked"
require "mock_suey/rspec/mock_context"

RSpec.configure do |config|
  config.before(:suite) do
    MockSuey.cook
  end

  config.after(:suite) do
    leftovers = MockSuey.eat

    next if leftovers.empty?

    failed_examples = Set.new

    leftovers.each do |call_obj|
      err = call_obj.metadata[:error]
      example = call_obj.metadata[:example]

      if example
        failed_examples << example
        MockSuey::RSpec.register_example_failure(example, err)
      else
        location = call_obj.metadata[:location]
        MockSuey::RSpec.report_non_example_failure(err, location)
      end
    end

    failed_examples.each do
      ::RSpec.configuration.reporter.example_failed(_1)
    end

    exit(RSpec.configuration.failure_exit_code)
  end
end
