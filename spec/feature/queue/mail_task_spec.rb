# frozen_string_literal: true

require "rails_helper"
require "mail_task"

RSpec.feature "MailTasks" do
  let(:user) { FactoryBot.create(:user) }

  before do
    User.authenticate!(user: user)
  end

  describe "Assigning a mail team task to a team member" do
    context "when task is assigned to AOD team" do

      let(:root_task) { FactoryBot.create(:root_task) }

      let(:mail_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )
      end

      let (:aod_team) { AodTeam.singleton }

      let(:aod_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: mail_team_task.id,
          assigned_to: aod_team
        )
      end

      before do
        OrganizationsUser.add_user_to_organization(user, aod_team)
      end

      it "successfully assigns the task to team member" do

        visit("queue/appeals/#{aod_team_task.appeal.external_id}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text:    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, user.full_name))
        expect(page.current_path).to eq("/queue")
        expect(aod_team_task.assigned_to_id).to eq(user.id)
        expect(root_task.children.length).to eq(1)
      end
    end
  end
end
