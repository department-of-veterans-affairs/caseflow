# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do

  self.use_transactional_tests = false

  context 'when appeals have been staged' do
    it 'refreshes the view and returns the proper appeals', bypass_cleaner: true do

      #AMA
      FactoryBot.create(:appeal, :with_schedule_hearing_tasks)
      FactoryBot.create(:appeal)

      #LEGACY
      case1 = FactoryBot.create(:case, bfkey: "700230001041", bfcorlid: "100000101011")
      case2 = FactoryBot.create(:case, bfkey: "700230002041", bfcorlid: "100000102021")

      FactoryBot.create(:legacy_appeal, :with_root_task, :with_veteran, vacols_case: case1)
      FactoryBot.create(:legacy_appeal, :with_schedule_hearing_tasks, :with_root_task, :with_veteran, vacols_case: case2)

      expect(NationalHearingQueueEntry.count).to eq 0
      NationalHearingQueueEntry.refresh
      expect(NationalHearingQueueEntry.count).to eq 2
    end
  end
end
