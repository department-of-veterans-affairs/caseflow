# frozen_string_literal: true

describe Seeds::Users do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of users and organizations", :aggregate_failures do
      expect { subject }.to_not raise_error
      expect(User.count).to eq(165)
      # This is creating 70 locally and 72 in GHA
      expect(Organization.count >= 70).to be true
      expect(VhaProgramOffice.count).to eq(5)
      expect(VhaRegionalOffice.count).to eq(18)
    end
  end
end
