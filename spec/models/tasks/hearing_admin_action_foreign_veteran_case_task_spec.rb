# frozen_string_literal: true

describe HearingAdminActionForeignVeteranCaseTask, :postgres do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:parent_hearing_task) { create(:hearing_task, parent: distribution_task) }
  let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: parent_hearing_task) }
  let!(:foreign_veteran_case_task) do
    HearingAdminActionForeignVeteranCaseTask.create!(
      appeal: appeal,
      parent: schedule_hearing_task,
      assigned_to: HearingsManagement.singleton,
      assigned_to_type: "Organization"
    )
  end
  let!(:user) { create(:user) }
  let!(:instructions_text) { "Instructions for the Schedule Hearing Task!" }

  context "as a hearing user" do
    before do
      HearingsManagement.singleton.add_user(user)

      RequestStore[:current_user] = user
    end

    it "has cancel, hold, and send to schedule veteran list actions" do
      available_actions = foreign_veteran_case_task.available_actions(user)

      expect(available_actions.length).to eq 3
      expect(available_actions).to include(
        Constants.TASK_ACTIONS.CANCEL_FOREIGN_VETERANS_CASE_TASK.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.to_h
      )
    end
  end

  context "after update" do
    let!(:regional_office_code) { "RO50" }

    before do
      HearingsManagement.singleton.add_user(user)

      RequestStore[:current_user] = user

      payload = {
        "status": Constants.TASK_STATUSES.completed,
        "instructions": instructions_text,
        "business_payloads": {
          "values": {
            "regional_office_value": regional_office_code
          }
        }
      }

      foreign_veteran_case_task.update_from_params(payload, user)
    end

    it "updates status code to completed" do
      expect(foreign_veteran_case_task.status).to eq Constants.TASK_STATUSES.completed
    end

    it "updates instructions on parent schedule hearing task" do
      expect(schedule_hearing_task.instructions.size).to eq 1
      expect(schedule_hearing_task.instructions[0]).to eq instructions_text
    end

    it "update RO on appeal" do
      expect(appeal.closest_regional_office).to eq regional_office_code
    end
  end
end
