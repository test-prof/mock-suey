# frozen_string_literal: true

shared_examples "accountant" do |class_name = Accountant|
  subject { class_name.new(tax_calculator: tax_calculator) }

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
