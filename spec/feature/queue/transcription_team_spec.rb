# frozen_string_literal: true

require "rails_helper"

RSpec.feature "TranscriptionTeam" do
  let(:transcription_team_member) { FactoryBot.create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(transcription_team_member, TranscriptionTeam.singleton)
    User.authenticate!(user: transcription_team_member)
  end

  describe "transcription team members should be able to complete transcription tasks" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) { FactoryBot.create(:disposition_task, parent: hearing_task, appeal: appeal) }
    let!(:transcription_task) { FactoryBot.create(:transcription_task, parent: disposition_task, appeal: appeal) }

    scenario "completes the task" do
      visit("/organizations/transcription")
      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h[:label])
      click_on "Mark complete"

      expect(page).to have_content("Bob Smith's case has been marked complete")
      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
    end

    scenario "cancels the task and sends appeal to hearings management" do
      visit("/organizations/transcription")
      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h[:label])
      click_on "Submit"

      expect(page).to have_content(
        format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_TITLE, appeal.veteran_full_name)
      )

      expect(transcription_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(root_task.children.where(type: HearingTask.name).count).to eq(2)
      open_hearing_task = root_task.children.find_by(type: HearingTask.name, status: Constants.TASK_STATUSES.on_hold)
      expect(open_hearing_task.children.first.type).to eq(ScheduleHearingTask.name)
      expect(open_hearing_task.children.first.assigned_to).to eq(Bva.singleton)
    end
  end
end
