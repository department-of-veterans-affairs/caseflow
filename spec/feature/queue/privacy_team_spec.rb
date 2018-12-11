RSpec.feature "Privacy team tasks and queue" do
  describe "Assigning ColocatedTask to Privacy team" do
    let(:attorney) { FactoryBot.create(:user) }

    let(:vlj_support_staff_team) { Colocated.singleton }
    let(:vlj_support_staff) { FactoryBot.create(:user) }

    let(:privacy_team) { PrivacyTeam.singleton }
    let(:privacy_team_member) { FactoryBot.create(:user) }

    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:colocated_task) do
      FactoryBot.create(
        :colocated_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: attorney,
        assigned_to: vlj_support_staff
      )
    end

    let(:instructions_text) { "Instructions from VLJ support staff to Privacy team." }

    before do
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
      OrganizationsUser.add_user_to_organization(vlj_support_staff, vlj_support_staff_team)
      OrganizationsUser.add_user_to_organization(privacy_team_member, privacy_team)
    end

    context "when appeal is a legacy appeal" do
      let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }

      before do
        # Disable this function as a temporary workaround until HearingsManagement.user_has_access? is fixed.
        # https://github.com/department-of-veterans-affairs/caseflow/blob/d4b9da68c8e4e7a416c8e9dc1cfe3e590eda2392/app/
        #   models/organizations/hearings_management.rb#L6
        allow_any_instance_of(HearingsManagement).to receive(:user_has_access?).and_return(false)
      end

      it "should be assigned and appear correctly" do
        # Log in as a member of the VLJ support staff and send the task to the Privacy team.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.external_id}")

        find(".Select-control", text: "Select an action…").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.label).click

        # Assignee dropdown selector should be hidden.
        expect(find_all(".Select-control").count).to eq(0)
        fill_in("taskInstructions", with: instructions_text)
        find("button", text: "Submit").click

        expect(page).to have_content("Task assigned to #{PrivacyTeam.singleton.name}")

        # Log in as Privacy team member.
        User.authenticate!(user: privacy_team_member)
        visit(privacy_team.path)

        # Case appears in organizational queue.
        expect(page).to have_content(appeal.veteran_file_number)

        # Task instructions do not appear on the case details page because we do not show instructions for legacy cases.
        # click_on(appeal.veteran_file_number)
        # expect(page).to have_content(instructions_text)
      end
    end

    context "when appeal is an AMA appeal" do
      let(:appeal) { FactoryBot.create(:appeal) }

      it "should be assigned and appear correctly" do
        # Log in as a member of the VLJ support staff and send the task to the Privacy team.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.external_id}")

        find(".Select-control", text: "Select an action…").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.label).click

        # Assignee dropdown selector should be hidden.
        expect(find_all(".Select-control").count).to eq(0)
        fill_in("taskInstructions", with: instructions_text)
        find("button", text: "Submit").click

        expect(page).to have_content("Task assigned to #{PrivacyTeam.singleton.name}")

        # Log in as Privacy team member.
        User.authenticate!(user: privacy_team_member)
        visit(privacy_team.path)

        # Case appears in organizational queue.
        click_on(appeal.veteran_file_number)

        # Case has task instructions.
        expect(page).to have_content(instructions_text)
      end
    end
  end
end
