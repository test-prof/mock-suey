# frozen_string_literal: true

describe "Post-suite patterns verification" do
  context "RSpec" do
    let(:env) { {"VERIFY_PATTERNS" => "true", "TRACING" => "true"} }

    specify do
      status, output = run_rspec("mock_context")

      expect(status).not_to be_success
      expect(output).to include("5 examples, 3 failures")
      expect(output).to include("Accountant #tax_rate_for")
      expect(output).to include("Accountant #net_pay")
      expect(output).to include("Mock contract verifications are missing")
      expect(output).to include_lines(
        *%w[
          No matching call found for:
          TaxCalculator#for_income: (-10) -> TaxCalculator::Result
          Captured calls:
          (-10) -> NilClass
        ]
      )
    end
  end
end
