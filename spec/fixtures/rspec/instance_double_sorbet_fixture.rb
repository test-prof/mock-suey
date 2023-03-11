# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator_sorbet"
require_relative "tax_calculator_spec"

describe AccountantSorbet do
  let!(:tax_calculator) {
    target = instance_double("TaxCalculatorSorbet")
    allow(target).to receive(:tax_rate_for).and_return(10)
    # FAILURE(typed): Return type is incorrect
    allow(target).to receive(:for_income).and_return(42)
    # FAILURE(contract): Return type doesn't match the passed arguments
    allow(target).to receive(:for_income).with(-10).and_return(TaxCalculator::Result.new(0))
    target
  }
  let!(:accountant) { AccountantSorbet.new(tax_calculator: tax_calculator) }

  it "sorbet_rspec" do
    unrelated_double = instance_double("Array")
    expect do
      described_class.new(tax_calculator: unrelated_double)
    end.to raise_error(TypeError, /.*Expected type TaxCalculator, got type RSpec::Mocks::InstanceVerifyingDouble.*/)
  end

  it "#net_pay" do
    expect(subject.net_pay(89)).to eq 47
  end

  it "#tax_rate_for" do
    # FAILURE(verified): Result in TaxCalucalor.tax_rate_for(40) calls,
    # which doesn't match the parameters
    expect(subject.tax_rate_for(40)).to eq(10)
  end

  describe "#tax_for" do
    specify "negative amount" do
      expect(subject.tax_for(-10)).to eq(0)
    end
  end
end
