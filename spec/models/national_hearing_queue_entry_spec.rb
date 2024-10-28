# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do
  self.use_transactional_tests = false

  context "when appeals have been staged" do
    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      # refresh in case anything was run in rails console previously
      NationalHearingQueueEntry.refresh

      # AMA
      FactoryBot.create(:appeal, :with_schedule_hearing_tasks)
      FactoryBot.create(:appeal)
      appeal_completed = FactoryBot.create(:appeal, :with_schedule_hearing_tasks)

      ScheduleHearingTask.find_by(appeal_id: appeal_completed.id, appeal_type: "Appeal").update(status: "completed")

      # LEGACY
      case1 = FactoryBot.create(:case, bfkey: "700230001041", bfcorlid: "100000101011")
      case2 = FactoryBot.create(:case, bfkey: "700230002041", bfcorlid: "100000102021")
      case3 = FactoryBot.create(:case, bfkey: "700230002042", bfcorlid: "100000102022")

      FactoryBot.create(:legacy_appeal,
                        :with_schedule_hearing_tasks,
                        :with_veteran,
                        vacols_case: case1)
      FactoryBot.create(:legacy_appeal,
                        :with_root_task,
                        :with_veteran,
                        vacols_case: case2)
      legacy_appeal_completed = FactoryBot.create(:legacy_appeal,
                                                  :with_schedule_hearing_tasks,
                                                  :with_veteran,
                                                  vacols_case: case3)

      ScheduleHearingTask.find_by(
        appeal_id: legacy_appeal_completed.id,
        appeal_type: "LegacyAppeal"
      ).update(status: "completed")

      expect(NationalHearingQueueEntry.count).to eq 0
      NationalHearingQueueEntry.refresh

      expect(NationalHearingQueueEntry.count).to eq 2
      # first created appeal is the only ama appeal that should be in the db (id: 1)
      expect(NationalHearingQueueEntry.first.appeal_id).to eq 1
      # first created legacy appeal is the only legacy appeal that should be in the db (id: 1)
      expect(NationalHearingQueueEntry.second.appeal_id).to eq 1

      clean_up_after_threads
    end
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
