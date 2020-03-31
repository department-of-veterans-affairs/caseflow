# frozen_string_literal: true

describe Api::V3::DecisionReview::HashPathValidator do
  let(:hash) { { a: { b: { c: 1 } } } }
  let(:path) { [:a, :b, :c] }
  let(:allowed_values) { [Integer] }
  let(:validator) do
    Api::V3::DecisionReview::HashPathValidator.new(
      hash: hash,
      path: path,
      allowed_values: allowed_values
    )
  end

  describe "#dig" do
    subject { validator.dig }

    context do
      it { is_expected.to eq(hash.dig(*path)) }
    end

    context do
      let(:allowed_values) { [] }
      it { is_expected.to eq(hash.dig(*path)) }
    end

    context do
      let(:path) { [:a, :b, :d] }
      it { is_expected.to be_nil }
    end

    context do
      let(:path) { [:a, :b, :c, :d] }
      it { expect { subject }.to raise_error TypeError }
    end
  end

  describe "#dig_string" do
    subject { validator.dig_string }

    context do
      it { is_expected.to eq("Got: 1") }
    end

    context do
      let(:allowed_values) { [] }
      it { is_expected.to eq("Got: 1") }
    end

    context do
      let(:hash) { { a: { b: { c: "hello" } } } }
      it { is_expected.to eq("Got: \"hello\"") }
    end

    context do
      let(:hash) { { a: { b: { c: nil } } } }
      it { is_expected.to eq("Got: nil") }
    end

    context do
      let(:path) { [:a, :b, :c, :d] }
      it { is_expected.to eq("Invalid path") }
    end
  end

  describe "#path_string" do
    subject { validator.path_string }

    context do
      let(:path) { ["a", 0, :b] }
      it { is_expected.to eq("[\"a\"][0][:b]") }
    end

    context do
      let(:path) { [] }
      it { is_expected.to eq("") }
    end

    context do
      let(:path) { [{}, [], nil] }
      it { is_expected.to eq("[{}][[]][nil]") }
    end
  end

  describe "#allowed_values_string" do
    subject { validator.allowed_values_string }

    context do
      let(:allowed_values) { [Numeric, nil, { x: 373 }] }
      it { is_expected.to eq("one of [Numeric, nil, {:x=>373}]") }
    end

    context do
      let(:allowed_values) { [] }
      it { is_expected.to eq("one of []") }
    end

    context do
      let(:allowed_values) { [Integer] }
      it { is_expected.to eq("a(n) integer") }
    end

    context do
      let(:allowed_values) { [TrueClass] }
      it { is_expected.to eq("a(n) trueClass") }
    end
  end

  describe "#path_is_valid?" do
    subject { validator.path_is_valid? }

    context do
      it { is_expected.to be true }
    end

    context do
      let(:path) { [:a, :b, :x] }
      it { is_expected.to be false }
    end

    context do
      let(:path) { [:a, :b, :c, :d] }
      it { is_expected.to be false }
    end

    context do
      let(:allowed_values) { [FalseClass, "pancake", [10, 9, 8]] }
      it { is_expected.to be false }
    end
  end

  describe "#error_msg" do
    subject { validator.error_msg }

    context do
      it { is_expected.to be nil }
    end

    context do
      let(:path) { [:a, :b, :x] }
      it { is_expected.to eq "[:a][:b][:x] should be a(n) integer. Got: nil." }
    end

    context do
      let(:path) { [:a, :b, :c, :d] }
      it { is_expected.to eq "[:a][:b][:c][:d] should be a(n) integer. Invalid path." }
    end

    context do
      let(:allowed_values) { [FalseClass, "pancake", [10, 9, 8]] }
      it do
        is_expected.to eq(
          "[:a][:b][:c] should be one of [FalseClass, \"pancake\", [10, 9, 8]]. Got: 1."
        )
      end
    end
  end
end
