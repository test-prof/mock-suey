# frozen_string_literal: true

module MockSuey
  module Ext
    module InstanceClass
      refine Class do
        def instance_class = self

        def instance_class_name = name
      end

      refine Class.singleton_class do
        def instance_class
          # TODO: replace with const_get
          eval(instance_class_name) # rubocop:disable Security/Eval
        end

        def instance_class_name = inspect.sub(%r{^#<Class:}, "").sub(/>$/, "")
      end
    end
  end
end
