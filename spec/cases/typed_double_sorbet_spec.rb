# frozen_string_literal: true

describe "Sorbet integration tests" do
  context "RSpec" do
    let(:env) { {"TYPED_SORBET" => "true"} }

    it "has no affect on simple double" do
      status, output = run_rspec("double_sorbet", env: env)

      expect(status).to be_success
      expect(output).to include("6 examples, 0 failures")
    end

    context "instance_double_sorbet" do
      it "enhances instance_double without extensions" do
        status, output = run_rspec("instance_double_sorbet", env: env)

        expect(status).not_to be_success
        expect(output).to include("16 examples")
        expect(output).to include("5 failures")
        expect(output).to include("AccountantSorbet#tax_rate_for")
        expect(output).to include("AccountantSorbet#net_pay")
        expect(output).to include("AccountantSorbet#tax_for")
      end
    end
  end
end
