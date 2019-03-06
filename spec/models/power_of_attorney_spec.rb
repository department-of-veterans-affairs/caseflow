# frozen_string_literal: true

describe PowerOfAttorney do
  let!(:vacols_case) { create(:case, :representative_american_legion) }
  let(:power_of_attorney) { PowerOfAttorney.new(vacols_id: vacols_case.bfkey, file_number: "VBMS-ID") }

  it "returns vacols values" do
    expect(power_of_attorney.vacols_representative_name).to eq "The American Legion"
  end

  context "when there is an attorney" do
    let!(:vacols_case) { create(:case) }
    let!(:representative) do
      create(
        :representative,
        repkey: vacols_case.bfkey,
        repaddr1: "123 Maple Ave.",
        repaddr2: "Apt 3",
        repcity: "Jersey City",
        repst: "NJ",
        repzip: "10001"
      )
    end

    it "sets the address" do
      expect(power_of_attorney.vacols_representative_address).to eq(
        address_line_1: "123 Maple Ave.",
        address_line_2: "Apt 3",
        city: "Jersey City",
        state: "NJ",
        zip: "10001"
      )
    end
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
