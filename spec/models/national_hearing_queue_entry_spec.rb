# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do
  self.use_transactional_tests = false

  # refresh in case anything was run in rails console previously
  before(:each) do
    NationalHearingQueueEntry.refresh
  end

  context "when appeals have been staged" do
    let!(:ama_with_sched_task) do
      FactoryBot.create(
        :appeal,
        :with_schedule_hearing_tasks,
        original_hearing_request_type: "central"
      )
    end

    let!(:ama_with_completed_status) do
      create(:appeal, :with_schedule_hearing_tasks).tap do |appeal|
        ScheduleHearingTask.find_by(appeal: appeal).completed!
      end
    end

    let!(:case1) { FactoryBot.create(:case, bfhr: "1", bfd19: 1.day.ago, bfac: "1") }
    let!(:case2) { FactoryBot.create(:case, bfhr: "2", bfd19: 2.days.ago, bfac: "5") }
    let!(:case3) { FactoryBot.create(:case, bfhr: "3", bfd19: 3.days.ago, bfac: "9") }

    let!(:legacy_with_sched_task) do
      FactoryBot.create(:legacy_appeal,
                        :with_schedule_hearing_tasks,
                        :with_veteran,
                        vacols_case: case1)
    end

    let!(:legacy_appeal_completed) do
      FactoryBot.create(:legacy_appeal,
                        :with_schedule_hearing_tasks,
                        :with_veteran,
                        vacols_case: case3).tap do |legacy_appeal|
                          ScheduleHearingTask.find_by(appeal: legacy_appeal).completed!
                        end
    end

    let!(:appeal_normal) do
      FactoryBot.create(:appeal)
    end

    let!(:legacy_appeal_normal) do
      FactoryBot.create(:legacy_appeal,
                        :with_root_task,
                        :with_veteran,
                        vacols_case: case2)
    end

    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(:appeal_id, :appeal_type)
      ).to match_array [
        [ama_with_sched_task.id, "Appeal"],
        [legacy_with_sched_task.id, "LegacyAppeal"]
      ]

      clean_up_after_threads
    end

    it "adds the Appeal info columns to the view in the proper format", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(
          :appeal_id, :appeal_type,
          :hearing_request_type, :receipt_date, :external_id,
          :appeal_stream, :docket_number
        )
      ).to match_array [
        [
          ama_with_sched_task.id,
          "Appeal",
          ama_with_sched_task.original_hearing_request_type,
          1.day.ago.strftime("%Y%m%d"),
          ama_with_sched_task.uuid,
          ama_with_sched_task.stream_type,
          ama_with_sched_task.stream_docket_number
        ],
        [
          legacy_with_sched_task.id,
          "LegacyAppeal",
          case1.bfhr,
          1.day.ago.strftime("%Y%m%d"),
          case1.bfkey,
          "Original",
          VACOLS::Folder.find_by_ticknum(case1.bfkey).tinum
        ]
      ]

      clean_up_after_threads
    end
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
