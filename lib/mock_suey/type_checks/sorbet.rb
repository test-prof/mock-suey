# frozen_string_literal: true

require "set"
require "pathname"

require "mock_suey/ext/instance_class"

module MockSuey
  module TypeChecks
    using Ext::InstanceClass

    class Sorbet
      def initialize(load_dirs: [])
        @load_dirs = Array(load_dirs)
      end

      def typecheck!(call_obj, raise_on_missing: false)
        method_name = call_obj.method_name
        mocked_instance = call_obj.mocked_instance
        unbound_mocked_method = mocked_instance.method(method_name).unbind
        args = call_obj.arguments

        unbound_original_method = call_obj.receiver_class.instance_method(method_name)
        original_method_sig = T::Private::Methods.signature_for_method(unbound_original_method)

        T::Private::Methods::CallValidation.validate_call(
          mocked_instance,
          unbound_mocked_method,
          original_method_sig,
          args,
          nil
        )
      end
    end
  end
end
