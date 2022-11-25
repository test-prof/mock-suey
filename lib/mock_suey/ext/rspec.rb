# frozen_string_literal: true

module MockSuey
  module Ext
    module RSpec
      # Provide unified interface to access target class
      # for different double/proxy types
      refine ::RSpec::Mocks::TestDoubleProxy do
        def target_class = nil
      end

      refine ::RSpec::Mocks::PartialDoubleProxy do
        def target_class = object.class
      end

      refine ::RSpec::Mocks::VerifyingPartialDoubleProxy do
        def target_class = object.class
      end

      refine ::RSpec::Mocks::PartialClassDoubleProxy do
        def target_class = object.singleton_class
      end

      refine ::RSpec::Mocks::VerifyingPartialClassDoubleProxy do
        def target_class = object.singleton_class
      end

      refine ::RSpec::Mocks::VerifyingProxy do
        def target_class = @doubled_module.target
      end

      refine ::RSpec::Mocks::Proxy do
        attr_reader :method_doubles
      end
    end
  end
end
