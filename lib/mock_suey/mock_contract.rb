# frozen_string_literal: true

require "mock_suey/ext/instance_class"

module MockSuey
  class MockContract
    using Ext::InstanceClass

    class Error < StandardError
      attr_reader :contract

      def initialize(contract, msg)
        @contract = contract
        super(msg)
      end

      private

      def captured_calls_message(calls)
        calls.map do |call|
          contract.args_pattern.map.with_index do |arg, i|
            (ANYTHING == arg) ? "_" : call.arguments[i].inspect
          end.join(", ").then do |args_desc|
            "    (#{args_desc}) -> #{call.return_value.class}"
          end
        end.uniq.join("\n")
      end
    end

    class NoMethodCalls < Error
      def initialize(contract)
        super(
          contract,
          "Mock contract verification failed:\n" \
          "  No method calls captured for #{contract.method_desc}"
        )
      end
    end

    class NoMatchingMethodCalls < Error
      def initialize(contract, real_calls)
        @contract = contract
        super(
          contract,
          "Mock contract verification failed:\n" \
          "  No matching calls captured for #{contract.pattern_desc}.\n" \
          "  Captured call patterns:\n" \
          "#{captured_calls_message(real_calls)}"
        )
      end
    end

    class NoMatchingReturnType < Error
      def initialize(contract, real_calls)
        @contract = contract
        super(
          contract,
          "Mock contract verification failed:\n" \
          "  No calls with the expected return type captured for #{contract.pattern_desc}.\n" \
          "  Captured call patterns:\n" \
          "#{captured_calls_message(real_calls)}"
        )
      end
    end

    ANYTHING = Object.new.freeze

    def self.from_stub(call_obj)
      call_obj => {receiver_class:, method_name:, return_value:}

      args_pattern = call_obj.arguments.map do
        contractable_arg?(_1) ? _1 : ANYTHING
      end

      new(
        receiver_class:,
        method_name:,
        args_pattern:,
        return_type: return_value.class
      )
    end

    def self.contractable_arg?(val)
      case val
      when TrueClass, FalseClass, Numeric, NilClass
        true
      when Array
        val.all? { |v| contractable_arg?(v) }
      when Hash
        contractable_arg?(val.values)
      else
        false
      end
    end

    attr_reader :receiver_class, :method_name,
      :args_pattern, :return_type

    def initialize(receiver_class:, method_name:, args_pattern:, return_type:)
      @receiver_class = receiver_class
      @method_name = method_name
      @args_pattern = args_pattern
      @return_type = return_type
    end

    def verify!(calls)
      raise NoMethodCalls.new(self) if calls.nil? || calls.empty?

      matching_input_calls = calls.select { matching_args?(_1) }
      raise NoMatchingMethodCalls.new(self, calls) if matching_input_calls.empty?

      matching_input_calls.each do
        return if _1.return_value.class <= return_type
      end

      raise NoMatchingReturnType.new(self, matching_input_calls)
    end

    def method_desc
      delimeter = receiver_class.singleton_class? ? "." : "#"

      "#{receiver_class.instance_class_name}#{delimeter}#{method_name}"
    end

    def pattern_desc
      args_pattern.map do
        (_1 == ANYTHING) ? "_" : _1.inspect
      end.join(", ").then do |args_desc|
        "#{method_desc}: (#{args_desc}) -> #{return_type}"
      end
    end

    private

    def matching_args?(call)
      args_pattern.each.with_index do |arg, i|
        next if arg == ANYTHING
        # Use case-eq here to make it possible to use composed
        # matchers in the future
        return false unless arg === call.arguments[i]
      end

      true
    end
  end
end
