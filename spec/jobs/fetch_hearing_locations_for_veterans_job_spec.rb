# frozen_string_literal: true

require "faker"

describe FetchHearingLocationsForVeteransJob, :all_dbs do
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
      Fakes::BGSService.store_veteran_record("123456789", veteran_record(file_number: "123456789S", state: "MA"))
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
        # AMA appeal with schedule task
        let!(:veteran_3) { create(:veteran, file_number: "000000000") }
        let!(:appeal) { create(:appeal, veteran_file_number: "000000000") }
        let!(:task_2) { create(:schedule_hearing_task, appeal: appeal) }

        # should not be returned
        before do
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
      before(:each) do
        allow_any_instance_of(VaDotGovAddressValidator).to receive(:update_closest_ro_and_ahls)
          .and_return(status: :matched_available_hearing_locations)
      end

      subject { FetchHearingLocationsForVeteransJob.new }

      it "creates schedule hearing tasks for appeal and records a geomatched result" do
        expect(subject).to receive(:record_geomatched_appeal)
          .with(legacy_appeal.external_id, :matched_available_hearing_locations)

        subject.perform

        expect(legacy_appeal.tasks.count).to eq(3)
        expect(legacy_appeal.tasks.open.where(type: "ScheduleHearingTask").count).to eq(1)
        expect(legacy_appeal.tasks.open.where(type: "HearingTask").count).to eq(1)
      end

      context "when appeal has open admin action" do
        before do
          HearingAdminActionVerifyAddressTask.create!(
            appeal: legacy_appeal,
            assigned_to: HearingsManagement.singleton,
            parent: ScheduleHearingTask.create(
              appeal: legacy_appeal,
              parent: RootTask.find_or_create_by(appeal: legacy_appeal)
            )
          )
        end

        it "closes admin action" do
          subject.perform

          expect(HearingAdminActionVerifyAddressTask.first.status).to eq(Constants.TASK_STATUSES.cancelled)
        end
      end

      context "when appeal can't be matched" do
        let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

        before do
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:update_closest_ro_and_ahls)
            .and_return(status: :created_verify_address_admin_action)
          AvailableHearingLocations.create(appeal: appeal, facility_id: "fake_152", updated_at: Time.zone.now - 15.days)
        end

        it "pushes appeal to the bottom of job query by creating a blank
            available_hearing_locations or touching an existing record" do
          subject.perform

          expect(legacy_appeal.available_hearing_locations.first.facility_id).to eq(nil)
          expect(appeal.available_hearing_locations.first.updated_at.strftime("%F")).to eq(Time.zone.now.strftime("%F"))
        end
      end

      context "when API limit is reached" do
        before(:each) do
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:update_closest_ro_and_ahls)
            .and_raise(Caseflow::Error::VaDotGovLimitError.new(code: 500, message: "Error"))
        end

        it "records a geomatch error" do
          expect(subject).to receive(:record_geomatched_appeal)
            .with(legacy_appeal.external_id, "limit_error")

          subject.perform
        end
      end

      context "when unknown error is thrown" do
        before(:each) do
          allow_any_instance_of(VaDotGovAddressValidator).to receive(:update_closest_ro_and_ahls)
            .and_raise(StandardError)
        end

        it "records a geomatch error" do
          expect(subject).to receive(:record_geomatched_appeal)
            .with(legacy_appeal.external_id, "error")
          expect(Raven).to receive(:capture_exception)

          subject.perform
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
end
