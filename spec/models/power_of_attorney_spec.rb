describe PowerOfAttorney do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let!(:vacols_case) { create(:case, :representative_american_legion) }
  let(:power_of_attorney) { PowerOfAttorney.new(vacols_id: vacols_case.bfkey, file_number: "VBMS-ID") }

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
end
