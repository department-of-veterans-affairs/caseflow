require "rails_helper"

RSpec.feature "ColocatedTask" do
  describe "attorney assigns task to vlj support staff, vlj returns it to attorney after completion" do
    let(:judge_user) { FactoryBot.create(:user) }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }

    let(:attorney_user) { FactoryBot.create(:user) }
    let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }

    let(:vlj_support_staff) { FactoryBot.create(:user) }

    before do
      FactoryBot.create(
        :ama_attorney_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )

      OrganizationsUser.add_user_to_organization(colocated_user, Colocated.singleton)
    end

    it "should return attorney task to active state" do
      # Attorney assigns task to VLJ support staff.
      User.authenticate!(user: attorney_user)
      visit("/queue/appeals/#{appeal.uuid}")

      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: COPY::ATTORNEY_CHECKOUT_ADD_ADMIN_ACTION_LABEL).click
      
      # Redirected to assign colocated action page
      action = Constants.CO_LOCATED_ADMIN_ACTIONS.poa_clarification
      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: action).click
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")
      find("button", text: "Assign Action").click

      # Redirected to personal queue page. Assignment succeeds.
      expect(page).to have_content(format(COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE, action))

      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")

      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: COPY::COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY).click

      

      # find(".Select-control", text: "Select a team").click
      # find("div", class: "Select-option", text: org.name).click
      # 

      # 

    end
  end
end
