# frozen_string_literal: true

describe Seeds::Jobs do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "seed data via jobs" do
      expect { subject }.to_not raise_error
    end
  end
end
