# frozen_string_literal: true

require "mock_suey/ext/instance_class"

module MockSuey
  using Ext::InstanceClass

  class MethodCall < Struct.new(
    :receiver_class,
    :method_name,
    :arguments,
    :return_value,
    :has_kwargs,
    :metadata,
    :mocked_instance,
    keyword_init: true
  )
    def initialize(**)
      super
      self.metadata = {} unless metadata
    end

    def pos_args
      return arguments unless has_kwargs
      *positional, _kwarg = arguments
      positional
    end

    def kwargs
      return {} unless has_kwargs
      arguments.last
    end

    def has_kwargs
      super.then do |val|
        # Flag hasn't been set explicitly,
        # so we need to derive it from the method data
        return val unless val.nil?

        kwarg_params = keyword_parameters
        return self.has_kwargs = false if kwarg_params.empty?

        last_arg = arguments.last

        unless last_arg.is_a?(::Hash) && last_arg.keys.all? { ::Symbol === _1 }
          return self.has_kwargs = false
        end

        self.has_kwargs = true
      end
    end

    def method_desc
      delimeter = receiver_class.singleton_class? ? "." : "#"

      "#{receiver_class.instance_class_name}#{delimeter}#{method_name}"
    end

    def inspect
      "#{method_desc}(#{arguments.map(&:inspect).join(", ")}) -> #{return_value.inspect}"
    end

    private

    def keyword_parameters
      arg_types = receiver_class.instance_method(method_name).parameters
      return [] if arg_types.any? { _1[0] == :nokey }

      arg_types.select { _1[0].start_with?("key") }
    end
  end
end
