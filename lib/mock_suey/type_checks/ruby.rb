# frozen_string_literal: true

gem "rbs", "~> 2.0"
require "rbs"
require "rbs/test"

require "set"
require "pathname"

require "mock_suey/ext/instance_class"

module MockSuey
  module TypeChecks
    using Ext::InstanceClass

    class Ruby
      class SignatureGenerator
        attr_reader :klass, :method_calls, :constants, :singleton
        alias_method :singleton?, :singleton

        def initialize(klass, method_calls)
          @klass = klass
          @singleton = klass.singleton_class?
          @method_calls = method_calls
          @constants = Set.new
        end

        def to_rbs
          [
            header,
            *method_calls.map { |name, calls| method_sig(name, calls) },
            footer
          ].join("\n")
        end

        private

        def header
          nesting_parts = klass.instance_class_name.split("::")

          base = Kernel
          nesting = 0

          lines = []

          nesting_parts.map do |const|
            base = base.const_get(const)
            lines << "#{"  " * nesting}#{base.is_a?(Class) ? "class" : "module"} #{const}"
            nesting += 1
          end

          @nesting = nesting_parts.size

          lines.join("\n")
        end

        def footer
          @nesting.times.map do |n|
            "#{"  " * (@nesting - n - 1)}end"
          end.join("\n")
        end

        def method_sig(name, calls)
          "#{"  " * @nesting}def #{singleton? ? "self." : ""}#{name}: (#{[args_sig(calls.map(&:pos_args)), kwargs_sig(calls.map(&:kwargs))].compact.join(", ")}) -> (#{return_sig(name, calls.map(&:return_value))})"
        end

        def args_sig(args)
          return if args.all?(&:empty?)

          args.transpose.map do |arg_values|
            arg_values.map(&:class).uniq.map do
              constants << _1
              "::#{_1.name}"
            end
          end.join(", ")
        end

        def kwargs_sig(kwargs)
          return if kwargs.all?(&:empty?)

          key_values = kwargs.each_with_object(Hash.new { |h, k| h[k] = [] }) { |pairs, acc|
            pairs.each { acc[_1] << _2 }
          }

          key_values.map do |key, values|
            values_sig = values.map(&:class).uniq.map do
              constants << _1
              "::#{_1.name}"
            end.join(" | ")

            "?#{key}: (#{values_sig})"
          end.join(", ")
        end

        def return_sig(name, values)
          # Special case
          return "self" if name == :initialize

          values.map(&:class).uniq.map do
            constants << _1
            "::#{_1.name}"
          end.join(" | ")
        end
      end

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

      def load_signatures_from_calls(calls)
        constants = Set.new

        calls.group_by(&:receiver_class).each do |klass, klass_calls|
          calls_per_method = klass_calls.group_by(&:method_name)
          generator = SignatureGenerator.new(klass, calls_per_method)

          generator.to_rbs.then do |rbs|
            MockSuey.logger.debug "Generated RBS for #{klass.instance_class_name}:\n#{rbs}\n"
            load_rbs(rbs)
          end

          constants |= generator.constants
        end

        constants.each do |const|
          next if type_defined?(const)

          SignatureGenerator.new(const, {}).to_rbs.then do |rbs|
            MockSuey.logger.debug "Generated RBS for constant #{const.instance_class_name}:\n#{rbs}\n"
            load_rbs(rbs)
          end
        end
      end

      private

      def load_rbs(rbs)
        ::RBS::Parser.parse_signature(rbs).then do |declarations|
          declarations.each do |decl|
            env << decl
          end
        end
      end

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

      def type_defined?(klass)
        !env.class_decls[type_for_class(klass.instance_class)].nil?
      end

      def reject_returned_doubles!(errors)
        return unless defined?(::RSpec::Core)

        errors.reject! do |error|
          case error
          in RBS::Test::Errors::ReturnTypeError[
            type:,
            value: ::RSpec::Mocks::InstanceVerifyingDouble => double
          ]
            return_class = type.instance_of?(RBS::Types::Bases::Self) ? error.klass : type.name
            return_type = return_class.to_s.gsub(/^::/, "")
            double_type = double.instance_variable_get(:@doubled_module).target.to_s

            double_type == return_type
          in RBS::Test::Errors::ReturnTypeError[
            value: ::RSpec::Mocks::Double
          ]
            true
          else
            false
          end
        end
      end
    end
  end
end
