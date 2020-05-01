# frozen_string_literal: true

describe Seeds::Defaults do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "passes args to FactoryBot" do
      expect { subject }.to_not raise_error
    end
  end
end
