require "rspec"

# frozen_string_literal: true

describe Reporter do
  class TestReporter
    include Reporter
  end

  describe "#average" do
    let(:reporter) { TestReporter.new }

    subject { reporter.average(items) }

    context "when there are no items" do
      let(:items) { [] }
      it "returns 0" do
        expect(subject).to eq 0
      end
    end

    context "when there is only one item" do
      let(:items) { [123] }
      it "returns that item" do
        expect(subject).to eq 123
      end
    end

    context "when passed two items" do
      let(:items) { [20, 30] }
      it "returns the average" do
        expect(subject).to eq 25
      end
    end
  end

  describe "#median" do
    let(:reporter) { TestReporter.new }
    subject { reporter.median(items) }

    describe "when called with an empty array" do
      let(:items) { [] }

      it "returns 0" do
        expect(subject).to eq 0
      end
    end

    describe "when called with one item" do
      let(:items) { [50] }

      it "returns that item" do
        expect(subject).to eq 50
      end
    end

    describe "when called with two items" do
      let(:items) { [50, 52] }

      it "returns the average" do
        expect(subject).to eq 51
      end
    end

    describe "when called with three items" do
      let(:items) { [1, 50, 51] }

      it "returns the middle item" do
        expect(subject).to eq 50
      end
    end

    describe "when called with four erratically spaced items" do
      let(:items) { [-10, 1, 5, 30_000] }
      it "returns the average of the middle two" do
        expect(subject).to eq 3
      end
    end

    describe "when called with an out-of-order set" do
      let(:items) { [2, -7, 1] }
      it "sorts the list and returns the true median" do
        expect(subject).to eq 1
      end
    end
  end
end
