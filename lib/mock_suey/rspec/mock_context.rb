# frozen_string_literal: true

require "mock_suey/ext/rspec"
require "mock_suey/ext/instance_class"

module MockSuey
  module RSpec
    # Special type of shared context for mocks.
    # The main difference is that it can track mocked classes and methods.
    module MockContext
      NAMESPACE = "mock::"

      class << self
        attr_writer :context_namespace

        def context_namespace = @context_namespace || NAMESPACE

        def collector = @collector ||= MocksCollector.new

        def registry = collector.registry
      end

      class MocksCollector
        using Ext::RSpec
        using Ext::InstanceClass

        # Registry contains all identified mocks/stubs in a form:
        #   Hash[Class: Hash[Symbol method_name, Array[MethodCall]]
        attr_reader :registry

        def initialize
          @registry = Hash.new { |h, k| h[k] = {} }
          @mocks = {}
        end

        def watch(context_id)
          return if mocks.key?(context_id)

          mocks[context_id] = true

          evaluate_context!(context_id)
        end

        private

        attr_reader :mocks

        def evaluate_context!(context_id)
          store = registry

          Class.new(::RSpec::Core::ExampleGroup) do
            def self.metadata = {}

            def self.filtered_examples = examples

            ::RSpec::Core::MemoizedHelpers.define_helpers_on(self)

            include_context(context_id)

            specify("true") { expect(true).to be(true) }

            after do
              ::RSpec::Mocks.space.proxies.values.each do |proxy|
                proxy.method_doubles.values.each do |double|
                  method_name = double.method_name
                  receiver_class = proxy.target_class

                  # Simple doubles don't have targets
                  next unless receiver_class

                  # TODO: Make conversion customizable (see proxy_method_invoked)
                  if method_name == :new && receiver_class.singleton_class?
                    receiver_class, method_name = receiver_class.instance_class, :initialize
                  end

                  expected_calls = store[receiver_class][method_name] = []

                  double.stubs.each do |stub|
                    arguments =
                      if stub.expected_args in [::RSpec::Mocks::ArgumentMatchers::NoArgsMatcher]
                        []
                      else
                        stub.expected_args
                      end

                    return_value = stub.implementation.terminal_action.call

                    expected_calls << MethodCall.new(
                      receiver_class:,
                      method_name:,
                      arguments:,
                      return_value:
                    )
                  end
                end
              end
            end
          end.run
        end
      end

      module DSL
        def mock_context(name, **opts, &block)
          ::RSpec.shared_context("#{MockContext.context_namespace}#{name}", **opts, &block)
        end
      end

      module ExampleGroup
        def include_mock_context(name)
          context_id = "#{MockContext.context_namespace}#{name}"

          MockContext.collector.watch(context_id)
          include_context(context_id)
        end
      end
    end
  end
end

# Extending RSpec
RSpec.extend(MockSuey::RSpec::MockContext::DSL)

if RSpec.configuration.expose_dsl_globally?
  Object.include(MockSuey::RSpec::MockContext::DSL)
  Module.extend(MockSuey::RSpec::MockContext::DSL)
end

RSpec::Core::ExampleGroup.extend(MockSuey::RSpec::MockContext::ExampleGroup)
RSpec::Core::ExampleGroup.extend(MockSuey::RSpec::MockContext::DSL)
