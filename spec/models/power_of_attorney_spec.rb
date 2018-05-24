describe PowerOfAttorney do
  let(:power_of_attorney) { PowerOfAttorney.new(vacols_id: "123C", file_number: "VBMS-ID") }

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
    it "gracefully handles error fetching address" do
      allow_any_instance_of(BGSService).to receive(:find_address_by_participant_id).and_raise(Savon::Error)
      expect(power_of_attorney.load_bgs_address!).to eq nil
      expect(power_of_attorney.bgs_participant_id).to_not eq nil
      expect(power_of_attorney.bgs_representative_address).to eq nil
    end
  end
end
