# frozen_string_literal: true

class TaxCalculator
  Result = Struct.new(:result, :tax_rate)

  TAX_BRACKETS = {
    10 => 0.1,
    40 => 0.12,
    90 => 0.22,
    170 => 0.24,
    215 => 0.32
  }.freeze

  def for_income(val)
    return if val < 0

    tax_rate = tax_rate_for(value: val)

    Result.new((tax_rate * val).to_i, tax_rate)
  end

  def tax_rate_for(value:)
    self.class.tax_rate_for(value: value)
  end

  def self.tax_rate_for(value:)
    TAX_BRACKETS.keys.find { _1 > value }.then { TAX_BRACKETS[_1] }
  end
end

class Accountant
  attr_reader :tax_calculator

  def initialize(tax_calculator: TaxCalculator.new)
    @tax_calculator = tax_calculator
  end

  def net_pay(val)
    val - tax_calculator.for_income(val)
  end

  def tax_for(val)
    tax_calculator.for_income(val).result
  end

  def tax_rate_for(value)
    tax_calculator.tax_rate_for(value)
  end
end
