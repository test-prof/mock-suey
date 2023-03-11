# frozen_string_literal: true

gem "sorbet-runtime"
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
        method_name = method_call.method_name
        mocked_obj = method_call.mocked_obj
        is_singleton = method_call.receiver_class.singleton_class?
        is_a_class = mocked_obj.is_a? Class
        unbound_mocked_method = if is_singleton
          mocked_obj.instance_method(method_name)
        else
          mocked_obj.method(method_name).unbind
        end
        args = method_call.arguments

        unbound_original_method = if is_a_class
          mocked_obj.method(method_name)
        else
          method_call.receiver_class.instance_method(method_name)
        end
        original_method_sig = T::Utils.signature_for_method(unbound_original_method)

        unless original_method_sig
          raise MissingSignature, RAISE_ON_MISSING_MESSAGE if raise_on_missing
          return
        end
        block = method_call.block

        T::Private::Methods::CallValidation.validate_call(
          mocked_obj,
          unbound_mocked_method,
          original_method_sig,
          args,
          block
        )
      end
    end
  end
end
