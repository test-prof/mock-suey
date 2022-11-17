# frozen_string_literal: true

describe "RSpec built-in doubles" do
  specify "double" do
    status, output = run_rspec("double")

    expect(status).to be_success
    expect(output).to include("5 examples, 0 failures")
  end

  specify "instance_double without extensions" do
    status, output = run_rspec("instance_double")

    expect(status).not_to be_success
    expect(output).to include("5 examples, 1 failure")
    expect(output).to include("Accountant #tax_rate_for")
    expect(output).to include("Missing required keyword arguments: value")
  end
end
