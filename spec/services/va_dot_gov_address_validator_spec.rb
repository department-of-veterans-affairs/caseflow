# frozen_string_literal: true

describe VaDotGovAddressValidator do
  include HearingHelpers

  describe "#update_closest_ro_and_ahls", :all_dbs do
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
    let!(:closest_facilities) do
      RegionalOffice.facility_ids.shuffle.map do |id|
        mock_facility_data(id: id)
      end
    end

    before(:each) do
      valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
      allow(valid_address_response).to receive(:data).and_return(valid_address)
      allow(valid_address_response).to receive(:error).and_return(valid_address_error)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
        .and_return(valid_address_response)

      closest_facility_response = ExternalApi::VADotGovService::FacilitiesResponse.new(mock_response)
      allow(closest_facility_response).to receive(:data).and_return(closest_facilities)
      allow(closest_facility_response).to receive(:error).and_return(nil)
      allow_any_instance_of(VaDotGovAddressValidator).to receive(:closest_facility_response)
        .and_return(closest_facility_response)
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

        expect(appeal.tasks.where(type: "HearingAdminActionVerifyAddressTask").count).to eq(1)
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

  describe "#facility_ids_to_geomatch", :all_dbs do
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

    context "when veteran with legacy appeal requests central office and does not live in DC, MD, or VA" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfhr: "1")) }
      subject { appeal.va_dot_gov_address_validator.facility_ids_to_geomatch }

      it "returns DC" do
        expect(subject).to match_array ["vba_372"]
      end
    end
  end

  describe "#valid_address when there is an address validation error", :postgres do
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
