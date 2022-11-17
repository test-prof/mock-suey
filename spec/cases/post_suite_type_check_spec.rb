# frozen_string_literal: true

describe "Post-suite typecheck with auto-generated types" do
  context "RSpec" do
    let(:env) { {"TYPED_DOUBLE" => "true", "TRACING" => "true"} }

    specify do
      status, output = run_rspec("mock_context")

      expect(status).not_to be_success
      expect(output).to include("5 examples, 2 failures")
      expect(output).to include("Accountant #tax_rate_for")
      expect(output).to include("Accountant #net_pay")
      expect(output).to include("TypeError: [TaxCalculator#for_income] ReturnTypeError")
    end
  end
end
