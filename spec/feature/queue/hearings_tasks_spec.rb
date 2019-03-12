# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Hearings tasks workflows" do
  let(:user) { FactoryBot.create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(user, HearingAdmin.singleton)
    User.authenticate!(user: user)
  end

  describe "Postponing a NoShowHearingTask" do
    let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:distribution_task) { FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task) }
    let(:parent_hearing_task) { FactoryBot.create(:hearing_task, parent: distribution_task, appeal: appeal) }
    let!(:completed_scheduling_task) do
      FactoryBot.create(:schedule_hearing_task, :completed, parent: parent_hearing_task, appeal: appeal)
    end
    let(:disposition_task) { FactoryBot.create(:disposition_task, parent: parent_hearing_task, appeal: appeal) }
    let!(:no_show_hearing_task) do
      FactoryBot.create(:no_show_hearing_task, parent: disposition_task, appeal: appeal)
    end

    it "closes current branch of task tree and starts a new one" do
      expect(distribution_task.children.count).to eq(1)
      expect(distribution_task.children.active.count).to eq(1)

      visit("/queue/appeals/#{appeal.uuid}")
      click_dropdown(text: Constants.TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.label)
      click_on(COPY::MODAL_SUBMIT_BUTTON)

      expect(page).to have_content("Success")

      expect(distribution_task.children.count).to eq(2)
      expect(distribution_task.children.active.count).to eq(1)

      new_parent_hearing_task = distribution_task.children.active.first
      expect(new_parent_hearing_task).to be_a(HearingTask)
      expect(new_parent_hearing_task.children.first).to be_a(ScheduleHearingTask)

      expect(distribution_task.ready_for_distribution?).to eq(false)
    end
  end
end
