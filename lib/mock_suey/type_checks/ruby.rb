# frozen_string_literal: true

gem "rbs", "~> 2.0"
require "rbs"
require "rbs/test"

require "pathname"

require "mock_suey/ext/instance_class"

module MockSuey
  module TypeChecks
    using MockSuey::Ext::InstanceClass

    class Ruby
      def initialize(load_dirs: [])
        @load_dirs = Array(load_dirs)
      end

      def typecheck!(call_obj, raise_on_missing: false)
        method_name = call_obj.method_name

        method_call = RBS::Test::ArgumentsReturn.return(
          arguments: call_obj.arguments,
          value: call_obj.return_value
        )

        call_trace = RBS::Test::CallTrace.new(
          method_name:,
          method_call:,
          # TODO: blocks support
          block_calls: [],
          block_given: false
        )

        method_type = type_for(call_obj.receiver_class, method_name)

        unless method_type
          raise MissingSignature, "No signature found for #{call_obj.method_desc}" if raise_on_missing
          return
        end

        self_class = call_obj.receiver_class
        instance_class = call_obj.receiver_class
        class_class = call_obj.receiver_class.singleton_class? ? call_obj.receiver_class : call_obj.receiver_class.singleton_class

        typecheck = RBS::Test::TypeCheck.new(
          self_class:,
          builder:,
          sample_size: 100, # What should be the value here?
          unchecked_classes: [],
          instance_class:,
          class_class:
        )

        errors = []
        typecheck.overloaded_call(
          method_type,
          "#{self_class.singleton_class? ? "." : "#"}#{method_name}",
          call_trace,
          errors:
        )

        reject_returned_doubles!(errors)

        # TODO: Use custom error class
        raise RBS::Test::Tester::TypeError.new(errors) unless errors.empty?
      end

      private

      def env
        return @env if instance_variable_defined?(:@env)

        loader = RBS::EnvironmentLoader.new
        @load_dirs&.each { loader.add(path: Pathname(_1)) }
        @env = RBS::Environment.from_loader(loader).resolve_type_names
      end

      def builder = @builder ||= RBS::DefinitionBuilder.new(env:)

      def type_for(klass, method_name)
        type = type_for_class(klass.instance_class)
        return unless env.class_decls[type]

        decl = klass.singleton_class? ? builder.build_singleton(type) : builder.build_instance(type)

        decl.methods[method_name]
      end

      def type_for_class(klass)
        *path, name = *klass.instance_class_name.split("::").map(&:to_sym)

        namespace = path.empty? ? RBS::Namespace.root : RBS::Namespace.new(absolute: true, path:)

        RBS::TypeName.new(name:, namespace:)
      end

      def reject_returned_doubles!(errors)
        return unless defined?(RSpec::Core)

        errors.reject! do |error|
          case error
          in RBS::Test::Errors::ReturnTypeError[
            type:,
            value: RSpec::Mocks::InstanceVerifyingDouble => double
          ]
            double.instance_variable_get(:@doubled_module).target.to_s == type.name.to_s.gsub(/^::/, "")
          else
            false
          end
        end
      end
    end
  end
end
