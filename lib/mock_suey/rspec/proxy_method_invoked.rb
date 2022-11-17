# frozen_string_literal: true

begin
  RSpec::Mocks::VerifyingMethodDouble
rescue LoadError
  warn "Couldn't find VerifyingMethodDouble class from rspec-mocks"
  return
end

module MockSuey
  module RSpec
    # Provide unified interface to access target class
    # for different double types
    using(Module.new do
      refine ::RSpec::Mocks::PartialDoubleProxy do
        def target_class = object.class
      end

      refine ::RSpec::Mocks::PartialClassDoubleProxy do
        def target_class = object.singleton_class
      end

      refine ::RSpec::Mocks::VerifyingProxy do
        def target_class = @doubled_module.target
      end
    end)

    module ProxyMethodInvokedHook
      def proxy_method_invoked(obj, *args, &block)
        return super if obj.is_a?(::RSpec::Mocks::TestDouble) && !obj.is_a?(::RSpec::Mocks::VerifyingDouble)

        method_call = MockSuey::MethodCall.new(
          receiver_class: @proxy.target_class,
          method_name: @method_name,
          arguments: args
        )

        super.tap do |ret|
          method_call.return_value = ret
          MockSuey.handle_mocked_call(method_call)
        end
      end
    end
  end
end

RSpec::Mocks::MethodDouble.prepend(MockSuey::RSpec::ProxyMethodInvokedHook)
