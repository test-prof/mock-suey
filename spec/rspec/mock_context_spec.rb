# frozen_string_literal: true

describe ".mock_context" do
  mock_context "example" do
    let(:double_hash) { double("Hash") }
    let(:instance_double_hash) { instance_double("Hash") }
    let(:instance_double_arr) { instance_double(Array) }
    let(:real_arr) { [1, 2, 3] }

    before do
      allow(double_hash).to receive(:to_a).and_return([0])

      allow(instance_double_hash).to receive(:key?).with("x").and_return(1)
      allow(instance_double_hash).to receive(:key?).with("y").and_return(nil)

      allow(real_arr).to receive(:take).with(1).and_return([0])
      allow(instance_double_arr).to receive(:size).with(no_args).and_return(42)

      allow(Regexp).to receive(:escape).and_return("bar")

      allow(TaxCalculator).to receive(:new).and_return(double)
    end
  end

  include_mock_context "example"

  let(:mocks) { MockSuey::RSpec::MockContext.registry }

  specify do
    expect(double_hash.to_a).to eq([0])
    expect(instance_double_hash.key?("x")).to eq(1)
    expect(real_arr.take(1)).to eq([0])
    expect(Regexp.escape("foo")).to eq("bar")
  end

  specify "registry" do
    expect(mocks.keys).to match_array([Hash, Array, Regexp.singleton_class, TaxCalculator])

    expect(mocks[Hash].keys).to match_array(%i[key?])
    expect(mocks[Array].keys).to match_array(%i[take size])
    expect(mocks[Regexp.singleton_class].keys).to match_array(%i[escape])
    expect(mocks[TaxCalculator].keys).to match_array(%i[initialize])

    expect(mocks[Hash][:key?].size).to eq(2)
    expect(mocks[Hash][:key?].map(&:arguments)).to match_array([
      ["x"],
      ["y"]
    ])
    expect(mocks[Hash][:key?].map(&:return_value)).to match_array([
      1,
      nil
    ])

    expect(mocks[Array][:take].size).to eq(1)
    expect(mocks[Array][:take].first).to have_attributes(
      arguments: [1],
      return_value: [0]
    )

    expect(mocks[Array][:size].size).to eq(1)
    expect(mocks[Array][:size].first).to have_attributes(
      arguments: [],
      return_value: 42
    )

    expect(mocks[Regexp.singleton_class][:escape].size).to eq(1)
    expect(mocks[Regexp.singleton_class][:escape].first).to have_attributes(
      arguments: [any_args],
      return_value: "bar"
    )

    expect(mocks[TaxCalculator][:initialize].size).to eq(1)
    expect(mocks[TaxCalculator][:initialize].first).to have_attributes(
      arguments: [any_args],
      return_value: instance_of(::RSpec::Mocks::Double)
    )
  end
end
