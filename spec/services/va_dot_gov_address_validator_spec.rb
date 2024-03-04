# frozen_string_literal: true

describe VaDotGovAddressValidator do
  include HearingHelpers

  describe "#update_closest_ro_and_ahls" do
    let!(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
    let!(:ro43_facility_id) { "vba_343" }
    let!(:closest_ro_facilities) do
      [
        mock_facility_data(id: ro43_facility_id)
      ]
    end
    let!(:available_hearing_locations_facilities) do
      [
        mock_facility_data(id: ro43_facility_id),
        mock_facility_data(id: "vba_343f")
      ]
    end

    subject { appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls }

    it "assigns a closest_regional_office and creates an available hearing location" do
      Appeal.first.va_dot_gov_address_validator.update_closest_ro_and_ahls

      ro = Appeal.first.closest_regional_office
      expect(ro).not_to be_nil
      expect(Appeal.first.available_hearing_locations.count).to eq(RegionalOffice.facility_ids_for_ro(ro).count)
    end

    context "when there is an existing available_hearing_location" do
      let!(:available_hearing_location) do
        AvailableHearingLocations.create(appeal: appeal)
      end

      it "removes existing available_hearing_locations" do
        subject
        expect(AvailableHearingLocations.where(id: available_hearing_location.id).count).to eq(0)
      end
    end

    shared_examples "verify address admin action" do
      it "creates Verify Address admin action" do
        subject
        expect(appeal.tasks.of_type(:HearingAdminActionVerifyAddressTask).count).to eq(1)
      end
    end

    context "when address is nil" do
      before do
        allow(appeal).to receive(:address).and_return(nil)
      end

      include_examples "verify address admin action"
    end

    context "when zip code is invalid" do
      before do
        allow_any_instance_of(ExternalApi::VADotGovService::ZipCodeValidationResponse)
          .to receive(:coordinates_invalid?).and_return(true)
      end

      include_examples "verify address admin action"
    end

    context "when veteran address is in a US territory without a regional office" do
      let(:us_territory_address) { Address.new(country: "US", state: "GU", city: "Yigo", zip: "96929") }

      before do
        allow_any_instance_of(ExternalApi::VADotGovService::ZipCodeValidationResponse)
          .to receive(:address).and_return(us_territory_address)
      end

      it "geomatches veteran to appriate US state or territory" do
        expect(appeal.closest_regional_office).to be_nil
        subject
        expect(appeal.closest_regional_office).to eq("RO59")
      end
    end

    context "when veteran has foreign address" do
      let(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
      let(:valid_zip_response) { ExternalApi::VADotGovService::ZipCodeValidationResponse.new(mock_response) }
      let(:response_body) { valid_zip_response.body }

      before do
        allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
          .and_return(valid_zip_response)
        allow(valid_zip_response).to receive(:coordinates_invalid?).and_return(true)
        allow(response_body).to receive(:dig).with(:addressMetaData, :addressType).and_return("International")
      end

      it "assigns closest regional office to RO11" do
        expect(appeal.closest_regional_office).to be_nil
        subject
        expect(appeal.closest_regional_office).to eq("RO11")
      end

      context "and lives in philippines" do
        before { allow_any_instance_of(Address).to receive(:country).and_return("Philippines") }

        it "assigns closest regional office to RO58 in Manila" do
          expect(appeal.closest_regional_office).to be_nil
          subject
          expect(appeal.closest_regional_office).to eq("RO58")
        end
      end
    end

    [
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new(code: 500, message: ""),
      Caseflow::Error::VaDotGovInvalidInputError.new(code: 500, message: ""),
      Caseflow::Error::VaDotGovMultipleAddressError.new(code: 500, message: "")
    ].each do |error|
      context "when va_dot_gov_service throws a #{error.class.name} error and zipcode fallback fails" do
        before do
          allow_any_instance_of(ExternalApi::VADotGovService::ZipCodeValidationResponse).to receive(:error)
            .and_return(error)
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:manually_validate_zip_code)
            .and_return(nil)
        end

        include_examples "verify address admin action"
      end
    end
  end

  describe "#ro_facility_ids_to_geomatch" do
    let!(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
    let!(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
    let!(:valid_address_state_code) { "VA" }
    let!(:valid_address_country_code) { "US" }
    let!(:valid_address) do
      {
        lat: 0.0,
        long: 0.0,
        city: "Fake City",
        full_address: "555 Fake Address",
        country_code: valid_address_country_code,
        state_code: valid_address_state_code,
        zip_code: "20035"
      }
    end

    subject { appeal.va_dot_gov_address_validator.ro_facility_ids_to_geomatch }

    before(:each) do
      valid_address_response = ExternalApi::VADotGovService::ZipCodeValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)
    end

    %w[GU PH VI].each do |state_code|
      context "when veteran lives in country/US territory with code #{state_code}" do
        let!(:valid_address_state_code) { state_code }
        let!(:expected_state_code) do
          {
            GU: "HI",
            VI: "PR",
            PW: "HI"
          }[state_code.to_sym]
        end

        it "returns facility ids for appropriate state" do
          expect(subject).to eq(RegionalOffice.ro_facility_ids_for_state(expected_state_code))
        end
      end
    end

    context "when veteran with legacy appeal requests central office" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfhr: "1")) }

      it "returns DC" do
        expect(subject).to match_array ["vba_372"]
      end
    end

    context "when veteran with legacy appeal lives in TX" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:valid_address_state_code) { "TX" }
    end

    context "when veteran with legacy appeal requests travel board" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfhr: "2")) }

      it "returns all facilities" do
        expect(subject).to match_array RegionalOffice.ro_facility_ids - ["vba_372"]
      end
    end
  end

  describe "#valid_address when there is an address validation error" do
    let!(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
    let!(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    let!(:valid_address) { {} }
    let!(:valid_address_error) do
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new(code: 500, message: "")
    end

    before do
      valid_address_response = ExternalApi::VADotGovService::ZipCodeValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(valid_address_error)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)
    end

    subject { appeal.va_dot_gov_address_validator.valid_address }

    it "falls back to zip_code validation" do
      # factory created zip code is 94103
      expect(subject[:lat]).to eq(37.773152)
      expect(subject[:long]).to eq(-122.411164)
    end
  end
end
