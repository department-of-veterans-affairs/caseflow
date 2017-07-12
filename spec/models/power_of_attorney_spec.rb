describe PowerOfAttorney do
  let(:power_of_attorney) { PowerOfAttorney.new(vacols_id: "123C", file_number: "VBMS-ID") }

  it "returns vacols values" do
    expect(power_of_attorney.vacols_representative_name).to eq "The American Legion"
  end

  it "returns bgs values" do
    power_of_attorney.load_bgs_record!
    expect(power_of_attorney.bgs_representative_name).to eq "Clarence Darrow"
  end

  it "returns bgs address" do
    power_of_attorney.load_bgs_record!
    expect(power_of_attorney.bgs_representative_address[:city]).to eq "SAN FRANCISCO"
  end

  describe "error handling" do
    let(:power_of_attorney) { PowerOfAttorney.new(bgs_participant_id: Fakes::BGSService::ID_TO_RAISE_ERROR) }

    it "gracefully handles error fetching address" do
      expect(power_of_attorney.bgs_participant_id).to eq Fakes::BGSService::ID_TO_RAISE_ERROR
      expect(power_of_attorney.load_bgs_address!).to eq nil
      expect(power_of_attorney.bgs_representative_address).to eq nil
    end
  end

  context "#vacols_rep_code" do
    subject { power_of_attorney.vacols_rep_code(representative_type, representative_name) }

    context "when representative type is not a service organization" do
      let(:representative_type) { "ARC" }
      let(:representative_name) { "PARALYZED VETERANS OF AMERICA" }

      it "it uses representative type to map to Vacols code" do
        expect(subject).to eq "C"
      end
    end

    context "when representative type is not found" do
      let(:representative_type) { "TGDF" }
      let(:representative_name) { "PARALYZED VETERANS OF AMERICA" }

      it { is_expected.to eq(nil) }
    end


    context "when representative type is a service organization" do
      let(:representative_type) { "Service Organization" }
      let(:representative_name) { "PARALYZED VETERANS OF AMERICA" }

      it "uses representative name to map to Vacols code" do
        expect(subject).to eq "G"
      end
    end

    context "when representative type is a service organization and representative name is not found" do
      let(:representative_type) { "Service Organization" }
      let(:representative_name) { "NOT EXISTING NAME" }

      it "maps to 'Other'" do
        expect(subject).to eq "O"
      end
    end
  end
end
