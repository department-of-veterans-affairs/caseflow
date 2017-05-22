describe PowerOfAttorney do
  let(:power_of_attorney) { PowerOfAttorney.new(vacols_id: "123C", vbms_id: "VBMS-ID")}

  it "returns vacols values" do
    power_of_attorney.vacols_representative_type = "American Legion"
  end

  it "returns bgs values" do
    power_of_attorney.bgs_representative_name = "Clarence Darrow"
  end
end
