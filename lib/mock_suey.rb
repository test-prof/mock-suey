# frozen_string_literal: true

require "logger"

require "mock_suey/version"
require "mock_suey/method_call"
require "mock_suey/type_checks"

module MockSuey
  class Configuration
    # No freezing this const to allow third-party libraries
    # to integrate with mock_suey
    TYPE_CHECKERS = %w[ruby]

    attr_accessor :debug,
      :store_mocked_calls,
      :type_checker,
      :signature_load_dirs,
      :raise_on_missing_types

    attr_writer :logger
    attr_reader :type_check

    def initialize
      @debug = %w[1 y yes true t].include?(ENV["MOCK_SUEY_DEBUG"])
      @store_mocked_calls = false
      @type_check = nil
      @signature_load_dirs = ["sig"]
      @raise_on_missing_types = false
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
  end

  class << self
    attr_reader :store_mocked_calls

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
    end

    # Run post-suite checks
    def eat
    end

    private

    def setup_type_checker
      return unless config.type_check

      # Allow configuring type checher manually
      unless config.type_checker
        require "mock_suey/type_checks/#{config.type_check}"
        const_name = config.type_check.split("_").map(&:capitalize).join

        config.type_checker = MockSuey::TypeChecks.const_get(const_name)
          .new(load_dirs: config.signature_load_dirs)

        logger.debug "Set up type checker: #{config.type_checker.class.name} (load_dirs: #{config.signature_load_dirs})"
      end

      raise_on_missing = config.raise_on_missing_types

      on_mocked_call do |call_obj|
        config.type_checker.typecheck!(call_obj, raise_on_missing:)
      end
    end

    def setup_mocked_calls_collection
      @store_mocked_calls = []

      on_mocked_call { @store_mocked_calls << _1 }
    end
  end
end

require "mock_suey/rspec" if defined?(RSpec::Core)
