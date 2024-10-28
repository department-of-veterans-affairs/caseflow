# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do
  self.use_transactional_tests = false

  # refresh in case anything was run in rails console previously
  before(:each) do
    NationalHearingQueueEntry.refresh
  end

  context "when appeals have been staged" do
    let!(:ama_with_sched_task) { FactoryBot.create(:appeal, :with_schedule_hearing_tasks) }
    let!(:ama_with_completed_status) { FactoryBot.create(:appeal, :with_schedule_hearing_tasks) }

    let!(:case1) { FactoryBot.create(:case, bfkey: "700230001041", bfcorlid: "100000101011") }
    let!(:case2) { FactoryBot.create(:case, bfkey: "700230002041", bfcorlid: "100000102021") }
    let!(:case3) { FactoryBot.create(:case, bfkey: "700230002042", bfcorlid: "100000102022") }

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
                        vacols_case: case3)
    end
    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      FactoryBot.create(:appeal)
      FactoryBot.create(:legacy_appeal,
                        :with_root_task,
                        :with_veteran,
                        vacols_case: case2)

      ScheduleHearingTask.find_by(
        appeal_id: ama_with_completed_status.id,
        appeal_type: "Appeal"
      ).update(status: "completed")

      ScheduleHearingTask.find_by(
        appeal_id: legacy_appeal_completed.id,
        appeal_type: "LegacyAppeal"
      ).update(status: "completed")

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
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
