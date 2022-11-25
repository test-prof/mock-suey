# frozen_string_literal: true

describe MockSuey::MockContract do
  let(:args_pattern) { [2020] }
  let(:return_type) { Integer }

  subject(:contract) do
    MockSuey::MockContract.new(
      receiver_class: TaxCalculator,
      method_name: :for_income,
      args_pattern:,
      return_type:
    )
  end

  describe ".from_stub" do
    let(:arguments) { [2020] }
    let(:return_value) { 202 }

    let(:stub_call) do
      MockSuey::MethodCall.new(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        arguments:,
        return_value:
      )
    end

    it "creates contract" do
      contract = described_class.from_stub(stub_call)

      expect(contract).to have_attributes(
        receiver_class: TaxCalculator,
        method_name: :for_income,
        args_pattern: [2020],
        return_type: Integer
      )
    end

    context "with contractable and any args" do
      let(:arguments) { ["2020", any_args] }

      specify do
        contract = described_class.from_stub(stub_call)

        expect(contract).to have_attributes(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          args_pattern: ["2020", described_class::ANYTHING],
          return_type: Integer
        )
        expect(contract).not_to be_noop
      end
    end

    context "with non-contractable arguments" do
      let(:stub_call) do
        MockSuey::MethodCall.new(
          receiver_class: Accountant,
          method_name: :initialize,
          arguments: [{tax_calculator: TaxCalculator.new}]
        )
      end

      it "creates contract" do
        contract = described_class.from_stub(stub_call)

        expect(contract).to have_attributes(
          receiver_class: Accountant,
          method_name: :initialize,
          args_pattern: [described_class::ANYTHING],
          return_type: NilClass
        )
        expect(contract).to be_noop
      end
    end
  end

  describe "verify!" do
    specify "no real calls" do
      expect { contract.verify!(nil) }.to raise_error(described_class::NoMethodCalls)
      expect { contract.verify!([]) }.to raise_error(described_class::NoMethodCalls)
    end

    specify "no calls matching args" do
      calls = [
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          arguments: [1989],
          return_value: 0
        )
      ]

      expect { contract.verify!(calls) }.to raise_error(described_class::NoMatchingMethodCalls)
    end

    specify "no calls matching return type" do
      calls = [
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          arguments: [2020],
          return_value: {rate: 10, value: 202}
        )
      ]

      expect { contract.verify!(calls) }.to raise_error(described_class::NoMatchingReturnType)
    end

    specify "with matching calls" do
      calls = [
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculator,
          method_name: :for_income,
          arguments: [2020],
          return_value: 10
        )
      ]

      expect { contract.verify!(calls) }.not_to raise_error
    end

    context "with hash/array args" do
      let(:args_pattern) { [{value: 2020, from: ["a"]}] }

      specify "with matching calls" do
        calls = [
          MockSuey::MethodCall.new(
            receiver_class: TaxCalculator,
            method_name: :for_income,
            arguments: [{value: 2020, from: ["a"]}],
            return_value: 10
          )
        ]

        expect { contract.verify!(calls) }.not_to raise_error
      end
    end
  end
end
