# frozen_string_literal: true

require "mock_suey/type_checks/sorbet"
require_relative "../fixtures/shared/tax_calculator_sorbet"

describe MockSuey::TypeChecks::Sorbet do
  subject(:checker) { described_class.new }

  context "with signatures" do
    let(:target) { instance_double("TaxCalculatorSorbet") }

    subject(:checker) do
      described_class.new
    end

    describe "type check argument type" do
      it "when correct" do
        allow(target).to receive(:simple_test).and_return(120)

        mcall = MockSuey::MethodCall.new(
          receiver_class: TaxCalculatorSorbet,
          method_name: :simple_test,
          arguments: [120],
          return_value: 120,
          mocked_instance: target
        )

        expect do
          checker.typecheck!(mcall)
        end.not_to raise_error
      end

      it "when incorrect" do
        allow(target).to receive(:simple_test).and_return(120)

        mcall = MockSuey::MethodCall.new(
          receiver_class: TaxCalculatorSorbet,
          method_name: :simple_test,
          arguments: ["120"],
          return_value: 120,
          mocked_instance: target
        )

        expect do
          checker.typecheck!(mcall)
        end.to raise_error(TypeError, /Parameter.*val.*Expected.*Integer.*got.*String.*/)
      end
    end

    describe "type check return type" do
      it "when correct" do
        allow(target).to receive(:simple_test).and_return(120)

        mcall = MockSuey::MethodCall.new(
          receiver_class: TaxCalculatorSorbet,
          method_name: :simple_test,
          arguments: [120],
          return_value: 120,
          mocked_instance: target
        )

        expect do
          checker.typecheck!(mcall)
        end.not_to raise_error
      end

      it "when incorrect" do
        allow(target).to receive(:simple_test).and_return("incorrect")

        mcall = MockSuey::MethodCall.new(
          receiver_class: TaxCalculatorSorbet,
          method_name: :simple_test,
          arguments: [120],
          return_value: 120,
          mocked_instance: target
        )

        expect do
          checker.typecheck!(mcall)
        end.to raise_error(TypeError, /.*Return value.*Expected.*Integer.*got.*String.*/)
      end
    end
  end
end
