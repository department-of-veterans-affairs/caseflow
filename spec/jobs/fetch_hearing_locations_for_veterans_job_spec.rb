# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob, :vacols do
  let!(:job) { FetchHearingLocationsForVeteransJob.new }

  describe "find_appeals_ready_for_geomatching" do
    let!(:legacy_appeal_with_ro_updated_one_day_ago) { create(:legacy_appeal, vacols_case: create(:case)) }
    let!(:hearing_location_updated_one_day_ago) do
      create(:available_hearing_locations,
             appeal_id: legacy_appeal_with_ro_updated_one_day_ago.id,
             appeal_type: "LegacyAppeal",
             city: "Holdrege",
             state: "NE",
             distance: 0,
             facility_type: "va_health_facility",
             updated_at: 1.day.ago)
    end
    let!(:task_with_ro_updated_one_day_ago) do
      create(:schedule_hearing_task, appeal: legacy_appeal_with_ro_updated_one_day_ago)
    end
    let!(:legacy_appeal_with_ro_updated_thirty_days_ago) { create(:legacy_appeal, vacols_case: create(:case)) }
    let!(:hearing_location_updated_thirty_days_ago) do
      create(:available_hearing_locations,
             appeal_id: legacy_appeal_with_ro_updated_thirty_days_ago.id,
             appeal_type: "LegacyAppeal",
             city: "Holdrege",
             state: "NE",
             distance: 0,
             facility_type: "va_health_facility",
             updated_at: 30.days.ago)
    end
    let!(:task_with_ro_updated_thirty_days_ago) do
      create(:schedule_hearing_task, appeal: legacy_appeal_with_ro_updated_thirty_days_ago)
    end
    let!(:legacy_appeal_without_ro) { create(:legacy_appeal, vacols_case: create(:case)) }
    let!(:task_without_ro) { create(:schedule_hearing_task, appeal: legacy_appeal_without_ro) }

    it "returns appeals in the correct order" do
      appeals_ready = job.find_appeals_ready_for_geomatching(LegacyAppeal)

      expect(appeals_ready.first.id).to eql(legacy_appeal_without_ro.id)
      expect(appeals_ready.second.id).to eql(legacy_appeal_with_ro_updated_thirty_days_ago.id)
      expect(appeals_ready.third.id).to eql(legacy_appeal_with_ro_updated_one_day_ago.id)
    end
  end

  context "when there is a case in location 57 *without* an associated veteran" do
    let!(:bfcorlid) { "123456789S" }
    let!(:bfcorlid_file_number) { "123456789" }
    let!(:vacols_case) do
      create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S", bfhr: "2", bfdocind: "V")
    end
    let!(:legacy_appeal) { create(:legacy_appeal, vbms_id: "123456789S", vacols_case: vacols_case) }

    before(:each) do
      Fakes::BGSService.veteran_records = { "123456789" => veteran_record(file_number: "123456789S", state: "MA") }
    end

    describe "#appeals" do
      context "when veterans exist in location 57 or have schedule hearing tasks" do
        # Legacy appeal with schedule hearing task
        let!(:veteran_2) { create(:veteran, file_number: "999999999") }
        let!(:vacols_case_2) do
          create(:case, bfcurloc: "CASEFLOW", bfregoff: "RO01", bfcorlid: "999999999S", bfhr: "2", bfdocind: "V")
        end
        let!(:legacy_appeal_2) { create(:legacy_appeal, vbms_id: "999999999S", vacols_case: vacols_case_2) }
        let!(:task_1) { create(:schedule_hearing_task, appeal: legacy_appeal_2) }
        # AMA appeal with schedule taks
        let!(:veteran_3) { create(:veteran, file_number: "000000000") }
        let!(:appeal) { create(:appeal, veteran_file_number: "000000000") }
        let!(:task_2) { create(:schedule_hearing_task, appeal: appeal) }
        # AMA appeal with completed address admin action
        let!(:veteran_4) { create(:veteran, file_number: "222222222") }
        let!(:appeal_2) { create(:appeal, veteran_file_number: "222222222") }
        let!(:task_3) { create(:schedule_hearing_task, appeal: appeal_2) }
        let!(:completed_admin_action) do
          create(
            :hearing_admin_action_verify_address_task,
            :completed,
            appeal: appeal_2,
            assigned_to: HearingsManagement.singleton,
            parent: task_3
          )
        end
        # should not be returned
        before do
          # tasks marked completed
          (0..2).each do |number|
            create(:veteran, file_number: "23456781#{number}")
            app = create(:appeal, veteran_file_number: "23456781#{number}")
            create(:schedule_hearing_task, :completed, appeal: app)
          end

          # task with Address admin action
          create(:veteran, file_number: "234567815")
          app_2 = create(:appeal, veteran_file_number: "234567815")
          tsk = create(:schedule_hearing_task, appeal: app_2)
          create(
            :hearing_admin_action_verify_address_task,
            appeal: app_2,
            assigned_to: HearingsManagement.singleton,
            parent: tsk
          )

          # task with Foreign Case admin action
          create(:veteran, file_number: "234567816")
          app_3 = create(:appeal, veteran_file_number: "234567816")
          tsk_2 = create(:schedule_hearing_task, appeal: app_3)
          create(
            :hearing_admin_action_verify_address_task,
            appeal: app_3,
            assigned_to: HearingsManagement.singleton,
            parent: tsk_2
          )

          # legacy not in location 57
          create(:veteran, file_number: "111111111")
          vac_case = create(:case, bfcurloc: "39", bfregoff: "RO01", bfcorlid: "111111111S", bfhr: "2", bfdocind: "V")
          create(:legacy_appeal, vbms_id: "111111111", vacols_case: vac_case)
        end

        it "returns only appeals with scheduled hearings tasks without an admin action or who are in location 57" do
          job.create_schedule_hearing_tasks
          expect(job.appeals.pluck(:id)).to contain_exactly(
            legacy_appeal.id, legacy_appeal_2.id, appeal.id
          )
        end
      end
    end

    describe "#perform" do
      let(:distance_response) { HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11).to_json) }
      let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body.to_json) }
      before do
        stub_const("VADotGovService", ExternalApi::VADotGovService)

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

      %w[AddressCouldNotBeFound InvalidRequestStreetAddress].each do |error|
        context "when va_dot_gov_service throws a #{error} error" do
          let(:validate_response) do
            HTTPI::Response.new(500, [], mock_validate_body(message_key: error).to_json)
          end
          let!(:vacols_case) do
            create(:case,
                   bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S", bfhr: "2", bfdocind: "V",
                   correspondent: create(:correspondent, saddrzip: "01002", saddrstt: "MA", saddrcnty: "USA"))
          end
          before do
            allow(VADotGovService).to receive(:send_va_dot_gov_request)
              .with(hash_including(endpoint: "address_validation/v1/validate"))
              .and_return(validate_response)
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
                     bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S", bfhr: "2", bfdocind: "V",
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

            context "and appeal already has schedule hearing task and is in location CASEFLOW" do
              let!(:vacols_case) do
                create(:case, bfcurloc: "CASEFLOW", bfregoff: "RO01", bfcorlid: "123456789S", bfhr: "2", bfdocind: "V")
              end
              let!(:legacy_appeal) { create(:legacy_appeal, vbms_id: "123456789S", vacols_case: vacols_case) }
              let!(:task) { create(:schedule_hearing_task, appeal: legacy_appeal) }

              it "creates an admin action" do
                FetchHearingLocationsForVeteransJob.perform_now
                expect(ScheduleHearingTask.first.id).to eq task.id
                expect(HearingAdminActionVerifyAddressTask.where(parent_id: task.id).count).to eq 1
              end
            end

            context "and job has already been run on a veteran" do
              it "only produces one admin action" do
                FetchHearingLocationsForVeteransJob.perform_now
                FetchHearingLocationsForVeteransJob.perform_now
                expect(HearingAdminActionVerifyAddressTask.count).to eq 1
              end
            end
          end
        end
      end

      context "when va_dot_gov_service returns a MultipleAddressError error" do
        let(:validate_response) do
          HTTPI::Response.new(500, [], mock_validate_body(message_key: "MultipleAddressError").to_json)
        end
        let!(:vacols_case) do
          create(:case,
                 bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S", bfhr: "2", bfdocind: "V",
                 correspondent: create(:correspondent, saddrzip: nil))
        end

        before do
          allow(VADotGovService).to receive(:send_va_dot_gov_request)
            .with(hash_including(endpoint: "address_validation/v1/validate"))
            .and_return(validate_response)
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
          before do
            Fakes::BGSService.veteran_records = {
              "123456789" => veteran_record(file_number: "123456789S", state: nil, zip_code: nil, country: nil)
            }
          end

          it "creates Verify Address Task" do
            FetchHearingLocationsForVeteransJob.perform_now
            tsk = ScheduleHearingTask.first
            expect(HearingAdminActionVerifyAddressTask.where(parent_id: tsk.id).count).to eq 1
          end
        end

        context "and veteran's address is in the Philippines" do
          before do
            allow(VADotGovService).to receive(:get_facility_data)
              .and_return([{ distance: nil, facility_id: "vba_358" }])
            Fakes::BGSService.veteran_records = {
              "123456789" => veteran_record(file_number: "123456789S",
                                            state: nil, zip_code: nil, country: "PHILIPPINES")
            }
          end

          it "associates appeals RO to RO58 and sets available_hearing_location" do
            FetchHearingLocationsForVeteransJob.perform_now
            expect(legacy_appeal.available_hearing_locations.count).to eq(1)
            expect(LegacyAppeal.first.closest_regional_office).to eq("RO58")
          end
        end
      end

      context "when veterans' states or country vary" do
        let(:veteran) { create(:veteran, file_number: bfcorlid_file_number) }
        let(:veteran_state) { "NH" }
        let(:validate_response) do
          HTTPI::Response.new(200, [], mock_validate_body(
            lat: 0.0, long: 0.0, state: veteran_state, country_code: "US"
          ).to_json)
        end
        let(:facility_ids) do
          facility_ids = []
          ros = RegionalOffice::CITIES.values.reject do |ro|
            ro[:facility_locator_id].nil? || ro[:state] != veteran_state
          end

          ros.each do |ro|
            facility_ids << ro[:facility_locator_id]
            facility_ids += ro[:alternate_locations] unless ro[:alternate_locations].nil?
          end

          facility_ids
        end
        let(:expected_ro) do
          RegionalOffice::CITIES.find do |_k, v|
            !v[:facility_locator_id].nil? && v[:state] == veteran_state
          end[0]
        end
        let(:vacols_case) do
          create(:case, bfcurloc: 57, bfregoff: nil, bfcorlid: bfcorlid, bfhr: "2", bfdocind: "V")
        end
        let(:body) do
          mock_distance_body(
            data: facility_ids.map { |id| mock_data(id: id) },
            distances: facility_ids.map.with_index do |id, index|
              mock_distance(distance: index, id: id)
            end
          )
        end
        let(:distance_response) { HTTPI::Response.new(200, [], body.to_json) }

        before do
          Fakes::BGSService.veteran_records = {
            "123456789": veteran_record(file_number: "123456789S", state: veteran_state)
          }
        end

        it "updates veteran closest_regional_office with fetched RO within veteran's state" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(LegacyAppeal.first.closest_regional_office).to eq expected_ro
        end

        context "but ROs for state are not found in facility locator" do
          let(:body) do
            mock_distance_body(
              data: [],
              distances: []
            )
          end

          it "sends error to Sentry" do
            expect(Raven).to receive(:capture_exception)
            FetchHearingLocationsForVeteransJob.perform_now
          end
        end

        [:GQ, :RP, :VQ].each do |country_code|
          context "when veteran country is in a US territory with country code #{country_code}" do
            let(:validate_response) do
              HTTPI::Response.new(200, [], mock_validate_body(
                lat: 0.0, long: 0.0, state: veteran_state, country_code: country_code.to_s
              ).to_json)
            end

            let(:expected_state) do
              {
                GQ: "HI",
                RP: "PI",
                VQ: "PR"
              }[country_code]
            end

            let(:facility_ids) do
              facility_ids = []
              ros = RegionalOffice::CITIES.values.reject do |ro|
                ro[:facility_locator_id].nil? || ro[:state] != expected_state
              end

              ros.each do |ro|
                facility_ids << ro[:facility_locator_id]
                facility_ids += ro[:alternate_locations] unless ro[:alternate_locations].nil?
              end

              facility_ids
            end

            let(:body) do
              mock_distance_body(
                data: facility_ids.map { |id| mock_data(id: id) },
                distances: facility_ids.map.with_index do |id, index|
                  mock_distance(distance: index, id: id)
                end
              )
            end
            let(:distance_response) { HTTPI::Response.new(200, [], body.to_json) }

            it "closest_regional_office is in appropriate state" do
              FetchHearingLocationsForVeteransJob.perform_now
              index = RegionalOffice::CITIES.values.find_index { |ro| ro[:state] == expected_state }
              expect(LegacyAppeal.first.closest_regional_office).to eq RegionalOffice::CITIES.keys[index]
            end
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

  def mock_validate_body(lat: 38.768185, long: -77.450033, state: "MA", country_code: "US", message_key: nil)
    response = {
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
    response["messages"] = [{ "key": message_key }] unless message_key.nil?
    response
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
