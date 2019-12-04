# frozen_string_literal: true

describe Api::V3::DecisionReview::HashPathValidator do
  describe "#dig" do
    let(:hash) { { a: { b: { c: 88 } } } }
    let(:allowed_values) { [Integer] }
    let(:path) { [:a, :b, :c] }
    subject do
      Api::V3::DecisionReview::HashPathValidator.new(
        hash: hash,
        path: path,
        allowed_values: allowed_values
      ).dig
    end
    
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
      it { expect {subject}.to raise_error TypeError }
    end
  end

  describe "#dig_string" do
    let(:hash) { { d: { e: { f: "hello" } } } }
    let(:path) { [:d, :e, :f] }
    let(:allowed_values) { [String] }
    subject do
      Api::V3::DecisionReview::HashPathValidator.new(
        hash: hash,
        path: path,
        allowed_values: allowed_values
      ).dig_string
    end
    
    context do
      it { is_expected.to eq("Got: \"hello\"") }
    end

    context do
      let(:allowed_values) { [] }
      it { is_expected.to eq("Got: \"hello\"") }
    end

    context do
      let(:path) { [:d, :e, :g] }
      it { is_expected.to eq("Got: nil") }
    end

    context do
      let(:path) { [:d, :e, :f, :g] }
      it { is_expected.to eq("Invalid path") }
    end
  end

  describe "#path_string" do
    subject do
      Api::V3::DecisionReview::HashPathValidator.new(
        hash: {},
        path: path,
        allowed_values: []
      ).path_string
    end
    
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
end
