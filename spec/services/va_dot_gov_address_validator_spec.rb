# frozen_string_literal: true

describe VaDotGovAddressValidator do
  include HearingHelpers

  describe "#closest_regional_office" do
    let(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
    let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
    let(:closest_ro_facilities) do
      [
        mock_facility_data(id: ro_facility_id)
      ]
    end
    let(:mock_address_validator) { VaDotGovAddressValidator.new(appeal: appeal) }

    before do
      closest_ro_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(closest_ro_response).to receive(:data).and_return(closest_ro_facilities)
      allow(closest_ro_response).to receive(:error).and_return(nil)

      allow(mock_address_validator).to receive(:closest_ro_response).and_return(closest_ro_response)
    end

    subject { mock_address_validator.closest_regional_office }

    context "when the closest RO is Boston" do
      let(:ro_facility_id) { "vba_301" } # Boston RO

      it "returns RO01" do
        expect(subject).to eq("RO01")
      end
    end

    context "when the closest RO is San Antonio" do
      let(:ro_facility_id) { "vha_671BY" } # San Antonio

      it "returns RO62 (Houston)" do
        expect(subject).to eq("RO62")
      end
    end
  end

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

    before(:each) do
      valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(valid_address_error)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)

      closest_ro_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(closest_ro_response).to receive(:data).and_return(closest_ro_facilities)
      allow(closest_ro_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:closest_ro_response)
        .and_return(closest_ro_response)

      available_hearing_locations_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(available_hearing_locations_response).to receive(:data)
        .and_return(available_hearing_locations_facilities)
      allow(available_hearing_locations_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:available_hearing_locations_response)
        .and_return(available_hearing_locations_response)
    end

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
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(AvailableHearingLocations.where(id: available_hearing_location.id).count).to eq(0)
      end
    end

    context "when address is nil" do
      before do
        allow(appeal).to receive(:address).and_return(nil)
      end

      it "creates Verify Address admin action" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(appeal.tasks.of_type(:HearingAdminActionVerifyAddressTask).count).to eq(1)
      end
    end

    context "when veteran state is outside US territories" do
      let(:valid_address_state_code) { "AE" }

      it "creates foreign veteran admin action" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(appeal.tasks.of_type(:HearingAdminActionForeignVeteranCaseTask).count).to eq(1)
      end
    end

    context "when veteran country is outside US territories" do
      let!(:valid_address_country_code) { "VN" }

      it "creates foreign veteran admin action" do
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

        expect(appeal.tasks.of_type(:HearingAdminActionForeignVeteranCaseTask).count).to eq(1)
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

          expect(appeal.tasks.of_type(:HearingAdminActionVerifyAddressTask).count).to eq(1)
        end

        context "and veteran's country is Philippines" do
          let(:address) do
            Address.new(country: "PHILIPPINES", city: "A City")
          end

          before do
            # this mocks get_facility_data call for ErrorHandler#check_for_philippines_and_maybe_update
            philippines_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
            allow(philippines_response).to receive(:data).and_return([mock_facility_data(id: "vba_358")])
            allow(philippines_response).to receive(:error).and_return(nil)
            allow(ExternalApi::VADotGovService).to receive(:get_facility_data)
              .and_return(philippines_response)

            allow(appeal).to receive(:address).and_return(address)
          end

          it "assigns closest regional office to Manila" do
            appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
            expect(appeal.closest_regional_office).to eq("RO58")
            expect(appeal.available_hearing_locations.first.facility_id).to eq("vba_358")
          end
        end
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

      it "adds San Antonio Satellite Office" do
        expect(subject).to match_array %w[vba_349 vba_362 vha_671BY]
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
