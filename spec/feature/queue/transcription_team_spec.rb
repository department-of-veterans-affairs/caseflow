require "rails_helper"

RSpec.feature "TranscriptionTeam" do
  let(:transcription_team_member) { FactoryBot.create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(transcription_team_member, TranscriptionTeam.singleton)
    User.authenticate!(user: transcription_team_member)
  end

  describe "transcription team members should be able to complete transcription tasks" do
    let!(:transcription_task) { FactoryBot.create(:transcription_task) }

    it "completes the task" do
      visit("/organizations/transcription")
      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h[:label])
      click_on "Mark complete"

      expect(page).to have_content("Bob Smith's case has been marked complete")
      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
    end

    it "completes the task and sends appeal to hearings management" do
      visit("/organizations/transcription")
      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h[:label])
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Recording error")
      click_on "Submit"

      expect(page).to have_content("Task reassigned to Hearings Management")
      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
      expect(ScheduleHearingTask.count).to eq(1)
      expect(ScheduleHearingTask.first.appeal).to eq(transcription_task.appeal)
      expect(ScheduleHearingTask.first.parent).to eq(transcription_task.parent)
    end
  end
end
