# frozen_string_literal: true

require_relative "../shared/tax_calculator"

describe TaxCalculator do
  subject { TaxCalculator.new }

  describe "#for_income" do
    specify "positive" do
      expect(subject.for_income(89).result).to eq(19)
    end

    specify "negative" do
      expect(subject.for_income(-10)).to be_nil
    end
  end
end
