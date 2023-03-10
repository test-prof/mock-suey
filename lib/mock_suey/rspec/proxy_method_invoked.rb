# frozen_string_literal: true

begin
  RSpec::Mocks::VerifyingMethodDouble
rescue LoadError
  warn "Couldn't find VerifyingMethodDouble class from rspec-mocks"
  return
end

require "mock_suey/ext/rspec"
require "mock_suey/ext/instance_class"

module MockSuey
  module RSpec
    using Ext::RSpec
    using Ext::InstanceClass

    module ProxyMethodInvokedHook
      def proxy_method_invoked(obj, *args, &block)
        return super if obj.is_a?(::RSpec::Mocks::TestDouble) && !obj.is_a?(::RSpec::Mocks::VerifyingDouble)

        receiver_class = @proxy.target_class
        method_name = @method_name

        # TODO: Make conversion customizable to support .perform_later -> #perform
        # and other similar use-cases
        if method_name == :new && receiver_class.singleton_class?
          receiver_class, method_name = receiver_class.instance_class, :initialize
        end

        method_call = MockSuey::MethodCall.new(
          mocked_obj: obj,
          receiver_class:,
          method_name:,
          arguments: args,
          block: block,
          metadata: {example: ::RSpec.current_example}
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
