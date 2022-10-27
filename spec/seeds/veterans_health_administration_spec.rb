# frozen_string_literal: true

describe Seeds::VeteransHealthAdministration do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates the CAMO Office" do
      expect { subject }.to_not raise_error
      expect(VhaCamo.count).to eq(1)
    end

    it "creates the Caregiver Support Office" do
      expect { subject }.to_not raise_error
      expect(VhaCaregiverSupport.count).to eq 1
    end

    it "creates all Program Offices" do
      expect { subject }.to_not raise_error
      expect(VhaProgramOffice.count).to eq(5)
    end

    it "creates all VISN organizations" do
      expect { subject }.to_not raise_error
      expect(VhaRegionalOffice.count).to eq(18)
    end
  end
end
