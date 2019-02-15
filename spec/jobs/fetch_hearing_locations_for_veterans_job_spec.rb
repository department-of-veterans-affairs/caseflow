require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob do
  let!(:job) { FetchHearingLocationsForVeteransJob.new }

  context "when there is a case in location 57 *without* an associated veteran" do
    let!(:bfcorlid) { "123456789S" }
    let!(:bfcorlid_file_number) { "123456789" }
    let!(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S") }
    let!(:legacy_appeal) { create(:legacy_appeal, vbms_id: "123456789S", vacols_case: vacols_case) }

    before(:each) do
      Fakes::BGSService.veteran_records = { "123456789" => veteran_record(file_number: "123456789S", state: "MA") }
    end

    describe "#appeals" do
      context "when veterans exist in location 57 or have schedule hearing tasks" do
        # Legacy appeal with schedule hearing task
        let!(:veteran_2) { create(:veteran, file_number: "999999999") }
        let!(:vacols_case_2) { create(:case, bfcurloc: "CASEFLOW", bfregoff: "RO01", bfcorlid: "999999999S") }
        let!(:legacy_appeal_2) { create(:legacy_appeal, vbms_id: "999999999S", vacols_case: vacols_case_2) }
        let!(:task_1) do
          ScheduleHearingTask.create!(appeal: legacy_appeal_2, assigned_to: HearingsManagement.singleton)
        end
        # AMA appeal with schedule taks
        let!(:veteran_3) { create(:veteran, file_number: "000000000") }
        let!(:appeal) { create(:appeal, veteran_file_number: "000000000") }
        let!(:task_2) { ScheduleHearingTask.create!(appeal: appeal, assigned_to: HearingsManagement.singleton) }
        # AMA appeal with completed address admin action
        let!(:veteran_4) { create(:veteran, file_number: "222222222") }
        let!(:appeal_2) { create(:appeal, veteran_file_number: "222222222") }
        let!(:task_3) { ScheduleHearingTask.create!(appeal: appeal_2, assigned_to: HearingsManagement.singleton) }
        let!(:completed_admin_action) do
          HearingAdminActionVerifyAddressTask.create!(
            appeal: appeal_2,
            assigned_to: HearingsManagement.singleton,
            parent: task_3,
            status: "completed"
          )
        end
        # should not be returned
        before do
          # tasks marked completed
          (0..2).each do |number|
            create(:veteran, file_number: "23456781#{number}")
            app = create(:appeal, veteran_file_number: "23456781#{number}")
            ScheduleHearingTask.create!(appeal: app, assigned_to: HearingsManagement.singleton, status: "completed")
          end

          # task with Address admin action
          create(:veteran, file_number: "234567815")
          app_2 = create(:appeal, veteran_file_number: "234567815")
          tsk = ScheduleHearingTask.create!(appeal: app_2, assigned_to: HearingsManagement.singleton)
          HearingAdminActionVerifyAddressTask.create!(
            appeal: app_2,
            assigned_to: HearingsManagement.singleton,
            parent: tsk
          )

          # task with Foreign Case admin action
          create(:veteran, file_number: "234567816")
          app_3 = create(:appeal, veteran_file_number: "234567816")
          tsk_2 = ScheduleHearingTask.create!(appeal: app_3, assigned_to: HearingsManagement.singleton)
          HearingAdminActionForeignVeteranCaseTask.create!(
            appeal: app_3,
            assigned_to: HearingsManagement.singleton,
            parent: tsk_2
          )

          # legacy not in location 57
          create(:veteran, file_number: "111111111")
          vac_case = create(:case, bfcurloc: "39", bfregoff: "RO01", bfcorlid: "111111111S")
          create(:legacy_appeal, vbms_id: "111111111", vacols_case: vac_case)
        end

        it "returns only appeals with scheduled hearings tasks without an admin action or who are in location 57" do
          expect(job.appeals.pluck(:id)).to contain_exactly(
            legacy_appeal.id, legacy_appeal_2.id, appeal.id, appeal_2.id
          )
        end
      end
    end

    describe "#validate_zip_code" do
      it "returns correct zip code" do
        job.validate_zip_code(legacy_appeal, error: nil)
      end
    end

    describe "#perform" do
      let(:distance_response) { HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11).to_json) }
      let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body.to_json) }
      before do
        VADotGovService = ExternalApi::VADotGovService

        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)
        allow(HTTPI).to receive(:post).with(instance_of(HTTPI::Request)).and_return(validate_response)
      end

      it "creates an available hearing location" do
        FetchHearingLocationsForVeteransJob.perform_now
        expect(AvailableHearingLocations.count).to eq 1
        expect(AvailableHearingLocations.first.distance).to eq 11.11
      end

      context "when closest_regional_office has to be fetched and only one RO/AHL is in veteran's state" do
        it "only fetches RO distance once" do
          expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).once
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.count).to eq 1
        end
      end

      context "when veteran requests central office" do
        let!(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S", bfhr: 1) }
        let(:distance_response) do
          HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11, id: "vba_372").to_json)
        end

        it "sets Central as closest_regional_office" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(LegacyAppeal.first.closest_regional_office).to eq "C"
        end
      end

      context "when veteran closest_regional_office is in state with multiple ROs/AHLs" do
        let(:facility_ids) do
          ohio_ro = RegionalOffice::CITIES["RO25"]
          [ohio_ro[:facility_locator_id]] + ohio_ro[:alternate_locations]
        end
        let(:distance_response) do
          HTTPI::Response.new(200, [], mock_distance_body(
            data: facility_ids.map { |id| mock_data(id: id) },
            distances: facility_ids.map { |id| mock_distance(id: id, distance: 1.1) }
          ).to_json)
        end
        let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body(state: "OH").to_json) }
        it "fetches RO distance twice" do
          expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).twice
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.count).to eq 4
        end
      end

      context "when there is an existing available_hearing_location" do
        let(:existing_location) do
          create(:available_hearing_locations, veteran_file_number: bfcorlid_file_number, distance: 22.22)
        end

        it "deletes existing location and creates a new location" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.where(distance: 22.22, veteran_file_number: bfcorlid_file_number))
            .to be_empty
          expect(AvailableHearingLocations.count).to eq 1
          expect(AvailableHearingLocations.first.distance).to eq 11.11
        end
      end

      context "when veteran state is outside US territories" do
        let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body(state: "AE").to_json) }

        it "creates a foreign veteran case admin action" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(HearingAdminActionForeignVeteranCaseTask.count).to eq 1
        end
      end

      context "when veteran country is outside US territories" do
        let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body(country_code: "SZ").to_json) }

        it "creates a foreign veteran case admin action" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(HearingAdminActionForeignVeteranCaseTask.count).to eq 1
        end
      end

      context "when va_dot_gov_service throws an Address error" do
        let!(:vacols_case) do
          create(:case,
                 bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S",
                 correspondent: create(:correspondent, saddrzip: "01002", saddrstt: "MA", saddrcnty: "USA"))
        end
        before do
          message = {
            "messages" => [
              {
                "key" => "AddressCouldNotBeFound"
              }
            ]
          }

          error = Caseflow::Error::VaDotGovServerError.new(code: "500", message: message)
          allow(VADotGovService).to receive(:send_va_dot_gov_request)
            .with(hash_including(endpoint: "address_validation/v1/validate")).and_raise(error)
          allow(VADotGovService).to receive(:send_va_dot_gov_request)
            .with(hash_including(endpoint: "va_facilities/v0/facilities"))
            .and_return(distance_response)
        end

        it "finds closest RO based on zipcode" do
          FetchHearingLocationsForVeteransJob.perform_now

          expect(LegacyAppeal.first.closest_regional_office).to eq "RO01"
          expect(LegacyAppeal.first.available_hearing_locations.count).to eq 1
        end

        context "and Veteran has no zipcode" do
          let!(:vacols_case) do
            create(:case,
                   bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S",
                   correspondent: create(:correspondent, saddrzip: nil))
          end
          before do
            Fakes::BGSService.veteran_records = {
              "123456789" => veteran_record(file_number: "123456789S", state: nil, zip_code: nil, country: nil)
            }
          end
          it "creates an ScheduleHearingTask and admin action" do
            FetchHearingLocationsForVeteransJob.perform_now
            tsk = ScheduleHearingTask.first
            expect(HearingAdminActionVerifyAddressTask.where(parent_id: tsk.id).count).to eq 1
          end

          context "and appeal already has schedule hearing task" do
            let!(:task) do
              ScheduleHearingTask.create!(appeal: legacy_appeal, assigned_to: HearingsManagement.singleton)
            end

            it "creates an admin action" do
              FetchHearingLocationsForVeteransJob.perform_now
              expect(ScheduleHearingTask.first.id).to eq task.id
              expect(HearingAdminActionVerifyAddressTask.where(parent_id: task.id).count).to eq 1
            end
          end

          context "and job has alreay been run on a veteran" do
            it "only produces one admin action" do
              FetchHearingLocationsForVeteransJob.perform_now
              FetchHearingLocationsForVeteransJob.perform_now
              expect(HearingAdminActionVerifyAddressTask.count).to eq 1
            end
          end
        end
      end
    end

    describe "#fetch_and_update_ro_for_appeal" do
      let(:veteran) { create(:veteran, file_number: bfcorlid_file_number) }
      let(:veteran_state) { "NH" }
      let(:mock_va_dot_gov_address) do
        {
          lat: 0.0,
          long: 0.0,
          state_code: veteran_state,
          country_code: "US"
        }
      end
      let(:facility_ros) do
        RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != veteran_state }
      end
      let(:expected_ro) do
        index = RegionalOffice::CITIES.values.find_index do |ro|
          !ro[:facility_locator_id].nil? && ro[:state] == veteran_state
        end
        RegionalOffice::CITIES.keys[index]
      end
      let(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: nil, bfcorlid: bfcorlid) }
      let(:body) do
        mock_distance_body(
          data: facility_ros.map { |ro| mock_data(id: ro[:facility_locator_id]) },
          distances: facility_ros.map.with_index do |ro, index|
            mock_distance(distance: index, id: ro[:facility_locator_id])
          end
        )
      end

      before do
        VADotGovService = ExternalApi::VADotGovService
        Fakes::BGSService.veteran_records = {
          "123456789": veteran_record(file_number: "123456789S", state: veteran_state)
        }

        distance_response = HTTPI::Response.new(200, [], body.to_json)
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)
      end

      it "updates veteran closest_regional_office with fetched RO within veteran's state" do
        job.fetch_and_update_ro_for_appeal(legacy_appeal, va_dot_gov_address: mock_va_dot_gov_address)
        expect(LegacyAppeal.first.closest_regional_office).to eq expected_ro
      end

      context "when ROs are not found in facility locator" do
        let(:body) do
          mock_distance_body(
            data: [],
            distances: []
          )
        end

        it "raises VADotGovServiceError" do
          expect { job.fetch_and_update_ro_for_appeal(legacy_appeal, va_dot_gov_address: mock_va_dot_gov_address) }
            .to raise_error(Caseflow::Error::VaDotGovAPIError)
        end
      end

      [:GQ, :RP, :VQ].each do |country_code|
        context "when veteran country is in a US territory with country code #{country_code}" do
          let(:mock_va_dot_gov_address) do
            {
              lat: 0.0,
              long: 0.0,
              state_code: veteran_state,
              country_code: country_code.to_s
            }
          end

          let(:expected_state) do
            {
              GQ: "HI",
              RP: "PI",
              VQ: "PR"
            }[country_code]
          end

          let(:facility_ros) do
            RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != expected_state }
          end

          it "closest_regional_office is in appropriate state" do
            job.fetch_and_update_ro_for_appeal(legacy_appeal, va_dot_gov_address: mock_va_dot_gov_address)
            index = RegionalOffice::CITIES.values.find_index { |ro| ro[:state] == expected_state }
            expect(LegacyAppeal.first.closest_regional_office).to eq RegionalOffice::CITIES.keys[index]
          end
        end
      end
    end
  end
  def veteran_record(file_number:, state: "MA", zip_code: "01002", country: "USA")
    {
      file_number: file_number,
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: "123456789",
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: "",
      city: "Roanoke",
      state: state,
      country: country,
      date_of_birth: "1977-07-07",
      zip_code: zip_code,
      military_post_office_type_code: "99999",
      military_postal_type_code: "99999",
      service: "99999"
    }
  end

  def mock_validate_body(lat: 38.768185, long: -77.450033, state: "MA", country_code: "US")
    {
      "address": {
        "county": {
          "name": "Manassas Park City"
        },
        "stateProvince": {
          "name": "Virginia",
          "code": state
        },
        "country": {
          "name": "United States",
          "fipsCode": country_code,
          "code": "USA"
        },
        "addressLine1": "8633 Union Pl",
        "city": "Manassas Park",
        "zipCode5": "20111"
      },
      "geocode": {
        "latitude": lat,
        "longitude": long
      }
    }
  end

  def mock_distance_body(distance: 0.0, id: "vba_301", data: nil, distances: nil)
    {
      "data": data || [mock_data(id: id)],
      "links": {
        "next": nil
      },
      "meta": {
        "distances": distances || [mock_distance(distance: distance, id: id)]
      }
    }
  end

  def mock_data(id:)
    {
      "id": id,
      "type": "va_facilities",
      "attributes": {
        "name": "Holdrege VA Clinic",
        "facility_type": "va_health_facility",
        "lat": 40.4454392100001,
        "long": -99.37959413,
        "address": {
          "physical": {
            "zip": "68949-1705",
            "city": "Holdrege",
            "state": "NE",
            "address_1": "1118 Burlington Street",
            "address_2": "",
            "address_3": nil
          }
        }
      }
    }
  end

  def mock_distance(distance:, id:)
    {
      "id": id,
      "distance": distance
    }
  end
end
