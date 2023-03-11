# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator_sorbet"
require_relative "tax_calculator_sorbet_spec"

describe AccountantSorbet do
  before do
    allow(tax_calculator).to receive(:for_income).and_return(42)
    allow(tax_calculator).to receive(:tax_rate_for).and_return(10.0)
    allow(tax_calculator).to receive(:for_income).with(-10).and_return(TaxCalculator::Result.new(0))
  end

  let(:tax_calculator) { double("TaxCalculatorSorbet") }

  include_examples "accountant", AccountantSorbet do
    it "incorrect" do
      # NOTE: in fact, sorbet-runtine also checks for type errors for ALL types
      expect { subject.net_pay("incorrect") }.to raise_error(TypeError)
    end
  end
end
