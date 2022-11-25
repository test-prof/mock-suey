# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../lib", __FILE__)

require_relative "./spec_helper"
require_relative "../shared/tax_calculator"

RSpec.configure do |config|
  config.after(:suite) do
    puts "Stored mocks: #{MockSuey.stored_mocked_calls.size}"
  end
end

describe "mocks" do
  let(:thing) { instance_double("Array") }

  before do
    allow(Array).to receive(:new).and_return(thing)
    allow(thing).to receive(:[]).and_return(42)
  end

  specify do
    expect(Array.new[1]).to eq(42) # rubocop:disable Style/EmptyLiteral
  end
end
