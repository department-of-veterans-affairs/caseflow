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
    expect(power_of_attorney.bgs_address[:city]).to eq "SAN FRANCISCO"
  end

  describe "error handling" do
    before do
      allow_any_instance_of(BGSService).to receive(:find_address_by_participant_id).and_raise("Ramalama")
    end

    let()

  end

  it "gracefully handles error fetching address" do
    expect(poa.bgs.find_address_by_participant_id("ptcpntid")).to raise_error("Ramalama")
    expect(poa.bgs_address).to eq nil
    expect(poa.bgs_address_not_found).to eq true
  end
end
