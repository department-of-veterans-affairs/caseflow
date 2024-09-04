# frozen_string_literal: true

describe Seeds::VeteransHealthAdministration do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates the CAMO Office, Caregiver Support Office, and Specialty Case Team org" do
      expect { subject }.to_not raise_error
      expect(VhaCamo.count).to eq 1
      expect(VhaCaregiverSupport.count).to eq 1
      expect(SpecialtyCaseTeam.count).to eq 1
    end
  end
end
