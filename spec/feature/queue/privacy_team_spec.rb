# frozen_string_literal: true

RSpec.feature "Privacy team tasks and queue", :all_dbs do
  describe "Assigning ColocatedTask to Privacy team" do
    let(:attorney) { create(:user) }

    let(:vlj_support_staff_team) { Colocated.singleton }
    let(:vlj_support_staff) { create(:user) }

    let(:privacy_team) { PrivacyTeam.singleton }
    let(:privacy_team_member) { create(:user) }

    let(:root_task) { create(:root_task, appeal: appeal) }
    let!(:colocated_task) do
      create(
        :colocated_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: attorney,
        assigned_to: vlj_support_staff
      )
    end

    let(:instructions_text) { "Instructions from VLJ support staff to Privacy team." }

    before do
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
      vlj_support_staff_team.add_user(vlj_support_staff)
      privacy_team.add_user(privacy_team_member)
    end

    context "when appeal is a legacy appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "should be assigned and appear correctly" do
        # Log in as a member of the VLJ support staff and send the task to the Privacy team.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.external_id}")

        find(".cf-select__control", text: "Select an action…").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.label).click

        # Assignee dropdown selector should be hidden.
        expect(find_all(".cf-modal-body .cf-select__control").count).to eq(0)
        fill_in("taskInstructions", with: instructions_text)
        find("button", text: "Submit").click

        expect(page).to have_content("Task assigned to #{PrivacyTeam.singleton.name}")

        # Log in as Privacy team member.
        User.authenticate!(user: privacy_team_member)
        visit(privacy_team.path)

        # Case appears in organizational queue.
        expect(page).to have_content(appeal.veteran_file_number)
      end
    end

    context "when appeal is an AMA appeal" do
      let(:appeal) { create(:appeal) }

      it "should be assigned and appear correctly" do
        # Log in as a member of the VLJ support staff and send the task to the Privacy team.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.external_id}")

        find(".cf-select__control", text: "Select an action…").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.label).click

        # Assignee dropdown selector should be hidden.
        expect(find_all(".cf-modal-body .cf-select__control").count).to eq(0)
        fill_in("taskInstructions", with: instructions_text)
        find("button", text: "Assign").click

        expect(page).to have_content("Task assigned to #{PrivacyTeam.singleton.name}")

        # Log in as Privacy team member.
        User.authenticate!(user: privacy_team_member)
        visit(privacy_team.path)

        # Case appears in organizational queue.
        click_on(appeal.veteran_file_number)

        # Case has task instructions.
        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click
        expect(page).to have_content(instructions_text)
      end
    end
  end
end
