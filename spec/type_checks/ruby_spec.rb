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
  end
end
