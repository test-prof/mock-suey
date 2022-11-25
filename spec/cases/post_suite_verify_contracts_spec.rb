# frozen_string_literal: true

describe "Post-suite contracts verification", :aggregate_failures do
  context "RSpec" do
    # Use trace_point to preserve default intstance_double behaviour
    let(:env) { {"VERIFY_CONTRACTS" => "true", "TRACE_VIA" => "trace_point"} }

    specify do
      status, output = run_rspec("mock_context", env:)

      expect(status).not_to be_success
      expect(output).to include("5 examples, 1 failure, 2 errors")
      expect(output).to include("Accountant #tax_rate_for")
      expect(output).to include("Mock contract verification failed")
      expect(output).to include("No calls with the expected return type captured for TaxCalculator#for_income: (-10) -> TaxCalculator::Result")
      expect(output).to include("No calls with the expected return type captured for TaxCalculator#for_income: (89) -> Integer")
    end
  end
end
