# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator_sorbet"
require_relative "tax_calculator_sorbet_spec"

describe AccountantSorbet do
  let!(:tax_calculator) { instance_double("TaxCalculatorSorbet") }
  let!(:accountant) { AccountantSorbet.new(tax_calculator: tax_calculator) }

  describe ".initialize checks handled by sorbet_rspec.rb" do
    it "correct param" do
      tc = TaxCalculatorSorbet.new
      expect { described_class.new(tax_calculator: tc) }.not_to raise_error
    end
    it "correct double" do
      tc = double("TaxCalculatorSorbet")
      expect { described_class.new(tax_calculator: tc) }.not_to raise_error
    end
    it "correct instance double" do
      tc = instance_double("TaxCalculatorSorbet")
      expect { described_class.new(tax_calculator: tc) }.not_to raise_error
    end
    it "correct instance double from parent class" do
      tc = instance_double("TaxCalculator")
      expect { described_class.new(tax_calculator: tc) }.not_to raise_error
    end
    it "unrelated double" do
      unrelated_double = instance_double("Array")
      expect do
        described_class.new(tax_calculator: unrelated_double)
      end.to raise_error(TypeError, /.*Expected type TaxCalculator, got type RSpec::Mocks::InstanceVerifyingDouble.*/)
    end
  end

  describe "#net_pay" do
    describe "without mocks" do
      let(:tax_calculator) { TaxCalculatorSorbet.new }
      it "raises ruby error because the method is intentionally written incorrectly" do
        expect { accountant.net_pay(10) }.to raise_error(TypeError, "TaxCalculator::Result can't be coerced into Integer")
        expect { accountant.net_pay(10) }.not_to raise_error # intentionaly
      end
    end

    describe "with mocks" do
      let!(:tax_calculator) do
        target = instance_double("TaxCalculatorSorbet")
        allow(target).to receive(:for_income).and_return(return_result)
        target
      end
      describe "with incorrect return" do
        let(:return_result) { Array }
        it "raises error because the method is intentionally written incorrectly" do
          expect { accountant.net_pay(10) }.to raise_error(TypeError)
          expect { accountant.net_pay(10) }.not_to raise_error # intentionaly
        end
      end
      describe "with correct return" do
        let!(:return_result) { TaxCalculator::Result.new(3, 33) }
        it "raises error because the method is intentionally written incorrectly" do
          expect { accountant.net_pay(10) }.to raise_error(TypeError)
          expect { accountant.net_pay(10) }.not_to raise_error # intentionaly
        end
      end
    end
  end

  describe "#tax_rate_for" do
    describe "without mocks" do
      let(:tax_calculator) { TaxCalculatorSorbet.new }
      it "succeeds" do
        expect { accountant.tax_rate_for(10) }.not_to raise_error
      end
    end

    describe "with mocks" do
      let!(:tax_calculator) do
        target = TaxCalculatorSorbet.new
        allow(target).to receive(:tax_rate_for).and_return(return_result)
        target
      end
      describe "with incorrect return" do
        let(:return_result) { "incorrect" }
        it "fails with TypeError" do
          expect { accountant.tax_rate_for(10) }.to raise_error(TypeError, /.*Return value.*Expected type Float, got type String.*/)
          expect { accountant.tax_rate_for(10) }.not_to raise_error # intentionaly
        end
      end
      describe "with correct return" do
        let(:return_result) { 0.333 }
        it "returns correct result" do
          expect(accountant.tax_rate_for(10)).to eq(0.333)
        end
      end
    end
  end

  describe "#tax_for" do
    describe "without mocks" do
      let(:tax_calculator) { TaxCalculatorSorbet.new }
      it "succeeds" do
        expect { accountant.tax_for(10) }.not_to raise_error
      end
    end

    describe "with mocks" do
      let!(:tax_calculator) do
        target = TaxCalculatorSorbet.new
        allow(target).to receive(:tax_rate_for).and_return(return_result)
        target
      end
      describe "with incorrect return" do
        let(:return_result) { Array }
        it "fails with NoMethodError because tax_rate_for does not have signature" do
          expect { accountant.tax_for(10) }.to raise_error(NoMethodError)
          expect { accountant.tax_for(10) }.not_to raise_error # intentionaly
        end
      end
      describe "with correct return" do
        let(:return_result) { 0.333 }
        it "returns correct result" do
          expect(accountant.tax_for(10)).to eq(3)
        end
      end
    end
  end
end
