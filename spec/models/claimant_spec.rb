describe Claimant do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:name) { nil }
  let(:relationship_to_veteran) { nil }
  let(:claimant_info) do
    {
      relationship: relationship_to_veteran
    }
  end

  let(:name_info) do
    {
      first_name: first_name,
      last_name: last_name
    }
  end

  let(:address_line_1) { nil }
  let(:address_line_2) { nil }
  let(:address_line_3) { nil }
  let(:city) { nil }
  let(:state) { nil }
  let(:zip_code) { nil }
  let(:country) { nil }
  let(:claimant_address) do
    {
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      city: city,
      country: country,
      state: state,
      zip: zip_code
    }
  end

  context "lazy loading instance attributes from BGS" do
    let(:claimant) { FactoryBot.create(:claimant) }

    context "when claimant exists in BGS" do
      let(:first_name) { "HARRY" }
      let(:last_name) { "POTTER" }
      let(:relationship_to_veteran) { "SON" }
      let(:address_line_1) { "4 Privet Dr" }
      let(:address_line_2) { "Little Whinging" }
      let(:city) { "Washington" }
      let(:state) { "DC" }
      let(:zip_code) { "20001" }
      let(:country) { "USA" }

      it "returns BGS attributes when accessed through instance" do
        allow_any_instance_of(Fakes::BGSService).to(
          receive(:find_address_by_participant_id).and_return(claimant_address)
        )

        allow_any_instance_of(Fakes::BGSService).to(
          receive(:fetch_claimant_info_by_participant_id).and_return(claimant_info)
        )

        allow_any_instance_of(Fakes::BGSService).to(
          receive(:fetch_person_info).and_return(name_info)
        )

        expect(claimant.name).to eq "Harry Potter"
        expect(claimant.relationship).to eq relationship_to_veteran
        expect(claimant.address_line_1).to eq address_line_1
        expect(claimant.address_line_2).to eq address_line_2
        expect(claimant.city).to eq city
        expect(claimant.state).to eq state
        expect(claimant.zip).to eq zip_code
        expect(claimant.country).to eq country
      end
    end
  end
end
