# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator"
require_relative "tax_calculator_spec"

mock_context "TaxCalculator" do
  let(:tax_calculator) { instance_double("TaxCalculator") }

  before do
    # FAILURE(typed): Return type is incorrect
    allow(tax_calculator).to receive(:for_income).with(89).and_return(42)
    allow(tax_calculator).to receive(:tax_rate_for).and_return(10.0)
    # FAILURE(contract): Return type doesn't match the passed arguments
    allow(tax_calculator).to receive(:for_income).with(-10).and_return(TaxCalculator::Result.new(0))
  end
end

describe Accountant do
  include_mock_context "TaxCalculator"
  include_examples "accountant"
end
