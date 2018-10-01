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
    expect(power_of_attorney.bgs_representative_name).to eq "Clarence Darrow"
  end

  it "returns bgs address" do
    expect(power_of_attorney.bgs_representative_address[:city]).to eq "SAN FRANCISCO"
  end

  describe "error handling" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_raise(Savon::Error)
    end

    it "gracefully handles error fetching address" do
      expect(power_of_attorney.bgs_representative_address).to eq nil
    end
  end
end
