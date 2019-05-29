# frozen_string_literal: true

describe HearingAdminActionForeignVeteranCaseTask, focus: true do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }
  let!(:foreign_veteran_case_task) do
    HearingAdminActionForeignVeteranCaseTask.create!(
      appeal: appeal,
      parent: schedule_hearing_task,
      assigned_to: HearingsManagement.singleton,
      assigned_to_type: "Organization"
    )
  end
  let!(:user) { FactoryBot.create(:user) }

  context "as a hearing user" do
    before do
      RequestStore[:current_user] = user
    end

    it "has cancel, hold, and send to schedule veteran list" do
      available_actions = foreign_veteran_case_task.available_actions(user)

      expect(available_actions.length).to eq 3
      expect(available_actions).to include(
        Constants.TASK_ACTIONS.CANCEL_FOREIGN_VETERANS_CASE_TASK.to_h,
        Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
        Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.to_h
      )
    end
  end
end
