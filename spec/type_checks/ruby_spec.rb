# frozen_string_literal: true

require "mock_suey/type_checks/ruby"
require_relative "../fixtures/shared/tax_calculator"

describe MockSuey::TypeChecks::Ruby do
  subject(:checker) { described_class.new }

  context "without signatures loaded" do
    it "type-checks core classes" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Array,
        method_name: :take,
        arguments: ["first"],
        return_value: 0
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ArgumentTypeError: expected `::int`/
      )
    end

    it "type-checks core singleton classes" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Regexp.singleton_class,
        method_name: :escape,
        arguments: [1]
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(RBS::Test::Tester::TypeError, /ArgumentTypeError: expected `::String | ::Symbol`/)
    end
  end

  context "with custom signatures" do
    subject(:checker) do
      described_class.new(load_dirs: File.expand_path(File.join(__dir__, "../fixtures/sig")))
    end

    it "type-checks custom classes" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        arguments: [120],
        return_value: 87
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ReturnTypeError: expected `::TaxCalculator::Result`/
      )
    end

    it "type-checks with instance double" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        arguments: [120],
        return_value: instance_double("TaxCalculator::Result")
      )

      expect do
        checker.typecheck!(mcall)
      end.not_to raise_error
    end

    it "type-checks custom singleton classes" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator.singleton_class,
        method_name: :tax_rate_for,
        arguments: [120],
        return_value: 20
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ArgumentError: expected method type \(value: ::Numeric\)/
      )
    end

    it "type-checks #initialize" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Accountant,
        method_name: :initialize,
        arguments: [TaxCalculator.new],
        return_value: nil
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ArgumentError: expected method type \(\?tax_calculator: ::TaxCalculator\)/
      )
    end

    it "type-checks #initialize with double return" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Accountant,
        method_name: :initialize,
        arguments: [{tax_calculator: TaxCalculator.new}],
        return_value: double("accountant")
      )

      expect do
        checker.typecheck!(mcall)
      end.not_to raise_error
    end

    it "type-checks #initialize with instance double return for correct class" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Accountant,
        method_name: :initialize,
        arguments: [{tax_calculator: TaxCalculator.new}],
        return_value: instance_double("Accountant")
      )

      expect do
        checker.typecheck!(mcall)
      end.not_to raise_error
    end

    it "type-checks #initialize with incorrect instance_double return" do
      mcall = MockSuey::MethodCall.new(
        receiver_class: Accountant,
        method_name: :initialize,
        arguments: [{tax_calculator: TaxCalculator.new}],
        return_value: instance_double("TaxCalculator")
      )

      expect do
        checker.typecheck!(mcall)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ReturnTypeError: expected `self`/
      )
    end
  end

  describe "#load_signatures_from_calls" do
    it "generates signatures from calls and load them into env", :aggregate_failures do
      calls = [
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          arguments: [120],
          return_value: 87
        ),
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          arguments: [0],
          return_value: nil
        ),
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator.singleton_class,
          method_name: :tax_rate_for,
          arguments: [120],
          return_value: {rate: 10.0, value: 12.0}
        ),
        MockSuey::MethodCall.new(
          receiver_class: Accountant,
          method_name: :initialize,
          arguments: [{tax_calculator: TaxCalculator.new}]
        )
      ]

      checker.load_signatures_from_calls(calls)

      invalid_arg_call = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        arguments: [{value: 125}],
        return_value: 87
      )

      expect do
        checker.typecheck!(invalid_arg_call)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ArgumentTypeError: expected `::Integer`/
      )

      invalid_return_call = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        arguments: [125],
        return_value: "13%"
      )

      expect do
        checker.typecheck!(invalid_return_call)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ReturnTypeError: expected `::Integer | ::NilClass`/
      )

      invalid_singleton_call = MockSuey::MethodCall.new(
        receiver_class: TaxCalculator.singleton_class,
        method_name: :tax_rate_for,
        arguments: [125],
        return_value: "13%"
      )

      expect do
        checker.typecheck!(invalid_singleton_call)
      end.to raise_error(
        RBS::Test::Tester::TypeError, /ReturnTypeError: expected `::Hash`/
      )

      kwargs_new_call = MockSuey::MethodCall.new(
        receiver_class: Accountant,
        method_name: :initialize,
        arguments: [{tax_calculator: TaxCalculator.new}],
        return_value: instance_double(Accountant)
      )

      expect do
        checker.typecheck!(kwargs_new_call)
      end.not_to raise_error
    end
  end
end
