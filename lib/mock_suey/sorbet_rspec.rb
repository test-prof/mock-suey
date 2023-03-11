# frozen_string_literal: true

require "sorbet-runtime"

# Let methods with sig receive double/instance_double arguments
T::Configuration.call_validation_error_handler = lambda do |signature, opts|
  is_mocked = opts[:value].is_a?(RSpec::Mocks::Double) || opts[:value].is_a?(RSpec::Mocks::VerifyingDouble)
  unless is_mocked
    return T::Configuration.send(:call_validation_error_handler_default, signature, opts)
  end

  # https://github.com/rspec/rspec-mocks/blob/main/lib/rspec/mocks/verifying_double.rb
  # https://github.com/rspec/rspec-mocks/blob/v3.12.3/lib/rspec/mocks/test_double.rb
  doubled_class = if opts[:value].is_a? RSpec::Mocks::Double
    doubled_class_name = opts[:value].instance_variable_get :@name
    Kernel.const_get(doubled_class_name)
  elsif opts[:value].is_a? RSpec::Mocks::VerifyingDouble
    opts[:value].instance_variable_get(:@doubled_module).send(:object)
  end
  are_related = doubled_class <= opts[:type].raw_type
  return if are_related

  return T::Configuration.send(:call_validation_error_handler_default, signature, opts)
end
