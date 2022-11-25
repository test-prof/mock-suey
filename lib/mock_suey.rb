# frozen_string_literal: true

require "logger"

require "mock_suey/version"
require "mock_suey/method_call"
require "mock_suey/type_checks"
require "mock_suey/tracer"
require "mock_suey/mock_contract"

module MockSuey
  class Configuration
    # No freezing this const to allow third-party libraries
    # to integrate with mock_suey
    TYPE_CHECKERS = %w[ruby]

    attr_accessor :debug,
      :store_mocked_calls,
      :signature_load_dirs,
      :raise_on_missing_types,
      :raise_on_missing_auto_types,
      :trace_real_calls,
      :trace_real_calls_via

    attr_writer :logger
    attr_reader :type_check, :auto_type_check, :verify_mock_contracts

    def initialize
      @debug = %w[1 y yes true t].include?(ENV["MOCK_SUEY_DEBUG"])
      @store_mocked_calls = false
      @type_check = nil
      @signature_load_dirs = ["sig"]
      @raise_on_missing_types = false
      @raise_on_missing_auto_types = true
      @trace_real_calls = false
      @auto_type_check = false
      @trace_real_calls_via = :prepend
    end

    def logger
      @logger || Logger.new(debug ? $stdout : IO::NULL)
    end

    def type_check=(val)
      if val.nil?
        @type_check = nil
        return
      end

      val = val.to_s
      raise ArgumentError, "Unsupported type checker: #{val}. Supported: #{TYPE_CHECKERS.join(",")}" unless TYPE_CHECKERS.include?(val)

      @type_check = val
    end

    def auto_type_check=(val)
      if val
        @trace_real_calls = true
        @store_mocked_calls = true
        @auto_type_check = true
      else
        @auto_type_check = val
      end
    end

    def verify_mock_contracts=(val)
      if val
        @trace_real_calls = true
        @verify_mock_contracts = true
      else
        @verify_mock_contracts = val
      end
    end
  end

  class << self
    attr_reader :stored_mocked_calls, :tracer, :stored_real_calls
    attr_accessor :type_checker

    def config = @config ||= Configuration.new

    def configure = yield config

    def logger = config.logger

    def on_mocked_call(&block)
      on_mocked_callbacks << block
    end

    def handle_mocked_call(call_obj)
      on_mocked_callbacks.each { _1.call(call_obj) }
    end

    def on_mocked_callbacks
      @on_mocked_callbacks ||= []
    end

    # Load extensions and start tracing if required
    def cook
      setup_type_checker
      setup_mocked_calls_collection if config.store_mocked_calls
      setup_real_calls_collection if config.trace_real_calls
    end

    # Run post-suite checks
    def eat
      @stored_real_calls = tracer.stop if config.trace_real_calls

      offenses = []

      if config.auto_type_check
        perform_auto_type_check(offenses)
      end

      if config.verify_mock_contracts
        perform_contracts_verification(offenses)
      end

      offenses
    end

    private

    def setup_type_checker
      return unless config.type_check

      # Allow configuring type checher manually
      unless type_checker
        require "mock_suey/type_checks/#{config.type_check}"
        const_name = config.type_check.split("_").map(&:capitalize).join

        self.type_checker = MockSuey::TypeChecks.const_get(const_name)
          .new(load_dirs: config.signature_load_dirs)

        logger.debug "Set up type checker: #{type_checker.class.name} (load_dirs: #{config.signature_load_dirs})"
      end

      raise_on_missing = config.raise_on_missing_types

      on_mocked_call do |call_obj|
        type_checker.typecheck!(call_obj, raise_on_missing:)
      end
    end

    def setup_mocked_calls_collection
      logger.debug "Collect mocked calls (MockSuey.stored_mocked_calls)"

      @stored_mocked_calls = []

      on_mocked_call { @stored_mocked_calls << _1 }
    end

    def setup_real_calls_collection
      logger.debug "Collect real calls via #{config.trace_real_calls_via} (MockSuey.stored_real_calls)"

      @tracer = Tracer.new(via: config.trace_real_calls_via)

      MockSuey::RSpec::MockContext.registry.each do |klass, methods|
        tracer.collect(klass, methods.keys)
      end

      tracer.start!
    end

    def perform_auto_type_check(offenses)
      raise "No type checker configured" unless type_checker

      # Generate signatures
      type_checker.load_signatures_from_calls(stored_real_calls)

      logger.info "Type check mocked calls against auto-generated signatures"

      # Verify stored mocked calls
      raise_on_missing = config.raise_on_missing_auto_types

      stored_mocked_calls.each do |call_obj|
        type_checker.typecheck!(call_obj, raise_on_missing:)
      rescue RBS::Test::Tester::TypeError, TypeChecks::MissingSignature => err
        call_obj.metadata[:error] = err
        offenses << call_obj
      end
    end

    def perform_contracts_verification(offenses)
      logger.info "Verify mock contracts"
      real_calls_per_class_method = stored_real_calls.group_by(&:receiver_class).tap do |grouped|
        grouped.transform_values! { _1.group_by(&:method_name) }
      end

      MockSuey::RSpec::MockContext.registry.each do |klass, methods|
        methods.values.flatten.each do |stub_call|
          contract = MockContract.from_stub(stub_call)
          contract.verify!(real_calls_per_class_method.dig(klass, stub_call.method_name))
        rescue MockContract::Error => err
          stub_call.metadata[:error] = err
          offenses << stub_call
        end
      end
    end
  end
end

require "mock_suey/rspec" if defined?(RSpec::Core)
