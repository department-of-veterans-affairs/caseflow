# frozen_string_literal: true

describe GeomatchService do
  include GeomatchHelper

  describe "#geomatch" do
    subject { described_class.new(appeal: appeal).geomatch }

    context "when there is a case in location 57 *without* an associated veteran" do
      let(:bfcorlid_file_number) { "123456789" }
      let(:bfcorlid) { "#{bfcorlid_file_number}S" }
      let(:vacols_case) do
        create(
          :case,
          bfcurloc: 57,
          bfregoff: "RO01",
          bfcorlid: bfcorlid,
          bfhr: "2",
          bfdocind: "V"
        )
      end
      let(:appeal) do
        create(
          :legacy_appeal,
          :with_schedule_hearing_tasks,
          vbms_id: bfcorlid,
          vacols_case: vacols_case
        )
      end
      let!(:veteran) { create(:veteran, file_number: bfcorlid_file_number, state: "MA") }

      before do
        allow_any_instance_of(VaDotGovAddressValidator).to(
          receive(:update_closest_ro_and_ahls)
            .and_return(status: :matched_available_hearing_locations)
        )
      end

      it "records a geomatched result" do
        setup_geomatch_service_mock(appeal) do |geomatch_service|
          expect(geomatch_service).to(
            receive(:record_geomatched_appeal).with(:matched_available_hearing_locations)
          )
        end

        subject
      end

      context "when appeal has open admin action" do
        before do
          HearingAdminActionVerifyAddressTask.create!(
            appeal: appeal,
            assigned_to: HearingsManagement.singleton,
            parent: ScheduleHearingTask.create(
              appeal: appeal,
              parent: RootTask.find_or_create_by(appeal: appeal)
            )
          )
        end

        it "closes admin action" do
          subject

          expect(HearingAdminActionVerifyAddressTask.first.status).to eq(Constants.TASK_STATUSES.cancelled)
        end
      end
    end

    context "for a travel board appeal in VACOLS" do
      let!(:vacols_case) do
        create(
          :case,
          bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
          bfhr: "2",
          bfdocind: nil,
          bfddec: nil
        )
      end
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

      it "geomatches for the travel board appeal" do
        subject

        legacy_appeal = LegacyAppeal.find_by(vacols_id: vacols_case.bfkey)

        expect(legacy_appeal).not_to be_nil
        expect(legacy_appeal.closest_regional_office).not_to be_nil
        expect(legacy_appeal.available_hearing_locations).not_to be_empty
      end
    end
  end
end
