# frozen_string_literal: true

describe Seeds::CaseDistributionLevers do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of levers" do
      expect { subject }.to_not raise_error
      expect(CaseDistributionLever.count).to eq(described_class.levers.count)
    end
  end
end
