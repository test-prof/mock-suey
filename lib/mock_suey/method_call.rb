# frozen_string_literal: true

require "mock_suey/ext/instance_class"

module MockSuey
  using MockSuey::Ext::InstanceClass

  class MethodCall < Struct.new(:receiver_class, :method_name, :arguments, :return_value, keyword_init: true)
    def method_desc
      delimeter = receiver_class.singleton_class? ? "." : "#"

      "#{receiver_class.instance_class_name}#{delimeter}#{method_name}"
    end
  end
end
