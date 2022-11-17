# frozen_string_literal: true

describe "Typed double extension" do
  context "RSpec" do
    let(:env) { {"TYPED_DOUBLE" => "true"} }

    it "has no affect on simple double" do
      status, output = run_rspec("double", env: env)

      expect(status).to be_success
      expect(output).to include("5 examples, 0 failures")
    end

    context "instance_double" do
      context "when signatures exist" do
        it "enhances instance_double without extensions" do
          env["RBS_SIG_PATH"] = File.expand_path(File.join(__dir__, "../fixtures/sig"))

          status, output = run_rspec("instance_double", env: env)

          expect(status).not_to be_success
          expect(output).to include("5 examples, 2 failures")
          expect(output).to include("Accountant #tax_rate_for")
          expect(output).to include("Accountant #net_pay")
          expect(output).to include("TypeError: [TaxCalculator#for_income] ReturnTypeError")
        end
      end

      context "when signatures do not exist" do
        it "behaves as regular instance_double" do
          status, output = run_rspec("instance_double", env: env)

          expect(status).not_to be_success
          expect(output).to include("5 examples, 1 failure")
        end
      end
    end
  end
end
