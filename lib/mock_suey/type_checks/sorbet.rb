# frozen_string_literal: true

gem "sorbet-runtime", "~> 0.5"
require "sorbet-runtime"
require "set"
require "pathname"

require_relative "../sorbet_rspec"
require "mock_suey/ext/instance_class"

module MockSuey
  module TypeChecks
    using Ext::InstanceClass

    class Sorbet
      RAISE_ON_MISSING_MESSAGE = "Please, set raise_on_missing_types to false to disable this error. Details: https://github.com/test-prof/mock-suey#raise_on_missing_types"

      def initialize(load_dirs: [])
        @load_dirs = Array(load_dirs)
      end

      def typecheck!(method_call, raise_on_missing: false)
        original_method_sig = get_original_method_sig(method_call)
        return sig_is_missing(raise_on_missing) unless original_method_sig

        unbound_mocked_method = get_unbound_mocked_method(method_call)
        override_mocked_method_to_avoid_recursion(method_call)

        validate_call!(
          instance: method_call.mocked_obj,
          original_method: unbound_mocked_method,
          method_sig: original_method_sig,
          args: method_call.arguments,
          blk: method_call.block
        )
      end

      private

      def validate_call!(instance:, original_method:, method_sig:, args:, blk:)
        T::Private::Methods::CallValidation.validate_call(
          instance,
          original_method,
          method_sig,
          args,
          blk
        )
      end

      def get_unbound_mocked_method(method_call)
        method_call.mocked_obj.method(method_call.method_name).unbind
      end

      def get_original_method_sig(method_call)
        unbound_original_method = get_unbound_original_method(method_call)
        T::Utils.signature_for_method(unbound_original_method)
      end

      def get_unbound_original_method(method_call)
        method_name = method_call.method_name
        mocked_obj = method_call.mocked_obj
        is_a_class = mocked_obj.is_a? Class

        if is_a_class
          method_call.mocked_obj.method(method_name)
        else
          method_call.receiver_class.instance_method(method_name)
        end
      end

      def sig_is_missing(raise_on_missing)
        raise MissingSignature, RAISE_ON_MISSING_MESSAGE if raise_on_missing
      end

      def override_mocked_method_to_avoid_recursion(method_call)
        method_name = method_call.method_name
        mocked_obj = method_call.mocked_obj
        return_value = method_call.return_value
        mocked_obj.define_singleton_method(method_name) { |*args, &block| return_value }
      end
    end
  end
end
