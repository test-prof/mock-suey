# frozen_string_literal: true

describe "MockSuey.stored_mocked_calls" do
  specify do
    status, output = run_rspec("stored_mocked_calls", env: {"STORE_MOCKS" => "true"})

    expect(status).to be_success
    expect(output).to include("1 example, 0 failures")
    expect(output).to include("Stored mocks: 2")
  end
end
