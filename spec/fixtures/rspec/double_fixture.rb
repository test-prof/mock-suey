# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator"
require_relative "tax_calculator_spec"

describe Accountant do
  let(:tax_calculator) { double("TaxCalculator") }

  before do
    allow(tax_calculator).to receive(:for_income).and_return(42)
    allow(tax_calculator).to receive(:tax_rate_for).and_return(10)
    allow(tax_calculator).to receive(:for_income).with(-10).and_return(TaxCalculator::Result.new(0))
  end

  include_examples "accountant"
end
