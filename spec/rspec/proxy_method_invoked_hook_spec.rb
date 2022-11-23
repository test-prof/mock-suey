# frozen_string_literal: true

describe "#proxy_method_invoked" do
  before(:all) do
    @mcalls = mcalls = []
    @was_callbacks = MockSuey.on_mocked_callbacks.dup
    MockSuey.on_mocked_callbacks.clear

    MockSuey.on_mocked_call { |mc| mcalls << mc }
  end

  after { mcalls.clear }

  after(:all) do
    MockSuey.on_mocked_callbacks.clear
    @was_callbacks.each { |clbk| MockSuey.on_mocked_callbacks(clbk) }
  end

  let(:mcalls) { @mcalls }

  it "#double" do
    target = double("Hash")
    allow(target).to receive(:key?).and_return(true)
    expect(target.key?("x")).to eq(true)

    expect(mcalls.size).to eq(0)
  end

  it "#instance_double with string" do
    target = instance_double("Hash")

    allow(target).to receive(:key?).and_return(true)
    expect(target.key?("x")).to eq(true)

    expect(mcalls.size).to eq(1)
    expect(mcalls.first).to have_attributes(
      receiver_class: Hash,
      method_name: :key?,
      arguments: ["x"],
      return_value: true
    )
  end

  it "#instance_double with module" do
    target = instance_double(Hash)

    allow(target).to receive(:key?).and_return(true)
    expect(target.key?("x")).to eq(true)

    expect(mcalls.size).to eq(1)
    expect(mcalls.first).to have_attributes(
      receiver_class: Hash,
      method_name: :key?,
      arguments: ["x"],
      return_value: true
    )
  end

  it "allow(instance).to" do
    target = {}

    allow(target).to receive(:key?).and_return(true)
    expect(target.key?("x")).to eq(true)

    expect(mcalls.size).to eq(1)
    expect(mcalls.first).to have_attributes(
      receiver_class: Hash,
      method_name: :key?,
      arguments: ["x"],
      return_value: true
    )
  end

  it "expect(instance).to" do
    target = {}

    expect(target).to receive(:key?).and_return(true)
    expect(target.key?("x")).to eq(true)

    expect(mcalls.size).to eq(1)
    expect(mcalls.first).to have_attributes(
      receiver_class: Hash,
      method_name: :key?,
      arguments: ["x"],
      return_value: true
    )
  end

  it "allow(module).to" do
    allow(Regexp).to receive(:escape).and_return("bar")
    expect(Regexp.escape("foo")).to eq("bar")

    expect(mcalls.size).to eq(1)
    expect(mcalls.first).to have_attributes(
      receiver_class: Regexp.singleton_class,
      method_name: :escape,
      arguments: ["foo"],
      return_value: "bar"
    )
  end

  it "allow(module).to receive(:new)" do
    hash_double = instance_double("Hash")
    allow(hash_double).to receive(:[]).and_return(10)
    allow(Hash).to receive(:new).and_return(hash_double)

    expect(Hash.new["a"]).to eq(10) # rubocop:disable Style/EmptyLiteral

    expect(mcalls.size).to eq(2)

    expect(mcalls.first).to have_attributes(
      receiver_class: Hash.singleton_class,
      method_name: :new,
      arguments: []
    )
    expect(mcalls.last).to have_attributes(
      receiver_class: Hash,
      method_name: :[],
      arguments: ["a"],
      return_value: 10
    )
  end
end
