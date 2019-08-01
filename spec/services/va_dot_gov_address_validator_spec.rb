# frozen_string_literal: true

require "rails_helper"
require "faker"

describe VaDotGovAddressValidator do
  describe "#update_closest_ro_and_ahls" do
    let!(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
    let!(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
    let!(:valid_address_country_code) { "US" }
    let!(:valid_address_state_code) { "PA" }
    let!(:valid_address_error) { nil }
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
    let!(:ro43_facility_id) { "vba_343" }
    let!(:closest_regional_office_facilities) do
      [mock_facility_data(id: ro43_facility_id)]
    end
    let!(:available_hearing_locations_facilities) do
      [
        mock_facility_data(id: ro43_facility_id),
        mock_facility_data(id: "vba_343f")
      ]
    end

    before(:each) do
      valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(valid_address_error)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)

      closest_regional_office_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(closest_regional_office_response).to receive(:data).and_return(closest_regional_office_facilities)
      allow(closest_regional_office_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:closest_regional_office_response)
        .and_return(closest_regional_office_response)

      available_hearing_locations_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(available_hearing_locations_response).to receive(:data)
        .and_return(available_hearing_locations_facilities)
      allow(available_hearing_locations_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:available_hearing_locations_response)
        .and_return(available_hearing_locations_response)
    end

    it "assigns a closest_regional_office and creates an available hearing location" do
      Appeal.first.va_dot_gov_address_validator.update_closest_ro_and_ahls

      available_hearing_locations = Appeal.first.available_hearing_locations.where(
        facility_id: available_hearing_locations_facilities.pluck(:facility_id)
      )

      expect(Appeal.first.closest_regional_office).to eq("RO43")
      expect(available_hearing_locations.count).to eq(2)
    end

    context "when there is an existing available_hearing_location" do
      let!(:available_hearing_location) do
        AvailableHearingLocations.create(appeal: appeal)
      end

      it "removes existing available_hearing_locations" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(AvailableHearingLocations.where(id: available_hearing_location.id).count).to eq(0)
      end
    end

    context "when veteran state is outside US territories" do
      let(:valid_address_state_code) { "AE" }

      it "creates foreign veteran admin action" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(appeal.tasks.where(type: "HearingAdminActionForeignVeteranCaseTask").count).to eq(1)
      end
    end

    context "when veteran country is outside US territories" do
      let!(:valid_address_country_code) { "VN" }

      it "creates foreign veteran admin action" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(appeal.tasks.where(type: "HearingAdminActionForeignVeteranCaseTask").count).to eq(1)
      end
    end

    [
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new(code: 500, message: ""),
      Caseflow::Error::VaDotGovInvalidInputError.new(code: 500, message: ""),
      Caseflow::Error::VaDotGovMultipleAddressError.new(code: 500, message: "")
    ].each do |error|
      context "when va_dot_gov_service throws a #{error.class.name} error and zipcode fallback fails" do
        let!(:valid_address_error) { error }

        before do
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:validate_zip_code)
            .and_return(nil)
        end

        it "creates a verify address admin action" do
          appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

          expect(appeal.tasks.where(type: "HearingAdminActionVerifyAddressTask").count).to eq(1)
        end
      end
    end

    ensure_stable do
      context "when validation fails and veteran's country is Philippines" do
        let!(:valid_address_error) do
          Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new(code: 500, message: "")
        end

        before do
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:validate_zip_code)
            .and_return(nil)
          # this mocks get_facility_data call for ErrorHandler#check_for_philippines_and_maybe_update
          philippines_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
          allow(philippines_response).to receive(:data).and_return([mock_facility_data(id: "vba_358")])
          allow(philippines_response).to receive(:error).and_return(nil)
          allow(ExternalApi::VADotGovService).to receive(:get_facility_data)
            .and_return(philippines_response)

          Fakes::BGSService.address_records = Hash[appeal.veteran_file_number, { cntry_nm: "PHILIPPINES" }]
        end

        it "assigns closest regional office to Manila" do
          appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

          expect(Appeal.find(appeal.id).closest_regional_office).to eq("RO58")
          expect(Appeal.find(appeal.id).available_hearing_locations.first.facility_id).to eq("vba_358")
        end
      end
    end
  end

  describe "#facility_ids_to_geomatch" do
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

    before(:each) do
      valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)
    end

    %w[GQ PH VI].each do |foreign_country_code|
      context "when veteran lives in country with code #{foreign_country_code}" do
        let!(:valid_address_country_code) { foreign_country_code }
        let!(:expected_state_code) do
          {
            GQ: "HI",
            PH: "PI",
            VI: "PR"
          }[foreign_country_code.to_sym]
        end

        subject { appeal.va_dot_gov_address_validator.facility_ids_to_geomatch }

        it "returns facility ids for appropriate state" do
          expect(subject).to eq(RegionalOffice.ro_facility_ids_for_state(expected_state_code))
        end
      end
    end

    context "when veteran with legacy appeal requests central office and does not live in DC, MD, or VA" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfhr: "1")) }
      subject { appeal.va_dot_gov_address_validator.facility_ids_to_geomatch }

      it "returns DC" do
        expect(subject).to match_array ["vba_372"]
      end
    end

    context "when veteran lives in Texas" do
      let!(:valid_address_state_code) { "TX" }
      subject { appeal.va_dot_gov_address_validator.facility_ids_to_geomatch }

      it "adds San Antonio Satellite Office" do
        expect(subject).to match_array %w[vba_349 vba_362 vha_671BY]
      end
    end

    context "when veteran with legacy appeal lives in MD" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:valid_address_state_code) { "MD" }
      subject { appeal.va_dot_gov_address_validator.facility_ids_to_geomatch }

      it "adds DC regional office" do
        expect(subject).to match_array %w[vba_313 vba_372]
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
      valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
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

def mock_facility_data(id:, city: "Fake City", state: "PA")
  {
    facility_id: id,
    type: "",
    distance: 10,
    facility_type: "",
    name: "Fake Name",
    classification: "",
    lat: 0.0,
    long: 0.0,
    address: "Fake Address",
    city: city,
    state: state,
    zip_code: "00000"
  }
end
