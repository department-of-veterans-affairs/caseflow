# frozen_string_literal: true

describe Seeds::VeteransHealthAdministration do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of decision reviews" do
      expect { subject }.to_not raise_error
      expect(VhaProgramOffice.count).to eq(6)
    end
  end
end
