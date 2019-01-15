require "rails_helper"

RSpec.feature "Task queue" do
  context "attorney user with assigned tasks" do
    let(:attorney_user) { FactoryBot.create(:user) }

    let!(:attorney_task) do
      FactoryBot.create(
        :ama_attorney_task,
        :on_hold,
        assigned_to: attorney_user
      )
    end

    let!(:paper_appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: attorney_user,
          folder: FactoryBot.build(:folder, :paper_case)
        )
      )
    end

    let(:vacols_tasks) { QueueRepository.tasks_for_user(attorney_user.css_id) }
    let(:attorney_on_hold_tasks) do
      Task.where(status: :on_hold, assigned_to: attorney_user)
    end

    before do
      User.authenticate!(user: attorney_user)
      visit "/queue"
    end

    context "the on-hold task is attached to an appeal with documents" do
      let!(:documents) { ["NOD", "BVA Decision", "SSOC"].map { |t| FactoryBot.build(:document, type: t) } }

      before do
        allow_any_instance_of(Appeal).to receive(:new_documents_for_user) { documents }
      end

      it "shows the correct number of tasks on hold" do
        expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))
      end
    end

    it "displays a table with a row for each case assigned to the attorney" do
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)
    end

    it "supports custom sorting" do
      docket_number_column_header = page.find(:xpath, "//thead/tr/th[3]/span/span[1]")
      docket_number_column_header.click
      docket_number_column_vals = page.find_all(:xpath, "//tbody/tr/td[3]/span[3]")
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
      docket_number_column_header.click
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
    end

    it "displays special text indicating an assigned case has paper documents" do
      expect(page).to have_content("#{paper_appeal.veteran_full_name} (#{paper_appeal.vbms_id.delete('S')})")
      expect(page).to have_content(COPY::IS_PAPER_CASE)
    end

    it "shows tabs on the queue page" do
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, vacols_tasks.length))
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, attorney_on_hold_tasks.length))
      expect(page).to have_content(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
    end

    it "shows the right number of cases in each tab" do
      # Assigned tab
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)

      # On Hold tab
      find("button", text: format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, attorney_on_hold_tasks.length)).click
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION)
      expect(find("tbody").find_all("tr").length).to eq(attorney_on_hold_tasks.length)
      appeal = attorney_task.appeal
      expect(page).to have_content("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
    end

    it "does not show queue switcher dropdown" do
      expect(page).to_not have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)
    end

    context "attorney user in an organization with assigned tasks" do
      let(:organization) { FactoryBot.create(:organization) }

      before do
        OrganizationsUser.add_user_to_organization(attorney_user, organization)
        attorney_user.reload
        visit "/queue"
      end

      it "shows queue switcher dropdown" do
        expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)
      end
    end
  end

  context "VSO employee" do
    let(:vso) do
      v = FactoryBot.create(:vso)
      Vso.find(v.id)
    end
    let(:vso_employee) { FactoryBot.create(:user, :vso_role) }
    let!(:vso_task) { FactoryBot.create(:ama_vso_task, :in_progress, assigned_to: vso) }
    before do
      User.authenticate!(user: vso_employee)
      allow_any_instance_of(Vso).to receive(:user_has_access?).and_return(true)
      visit(vso.path)
    end

    it "should be able to take actions on task from VSO queue" do
      expect(page).to have_content(COPY::ORGANIZATION_QUEUE_TABLE_TITLE % vso.name)

      case_details_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      case_details_link.click
      expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTION_BOX_TITLE)

      # Marking the task as complete correctly changes the task's status in the database.
      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      find("button", text: "Mark complete").click

      expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, vso_task.appeal.veteran_full_name))
      expect(Task.find(vso_task.id).status).to eq("completed")
    end
  end

  describe "Creating a mail task" do
    let(:mail_user) { FactoryBot.create(:user) }
    let(:mail_team) { MailTeam.singleton }
    let(:appeal) { FactoryBot.create(:appeal) }

    before do
      OrganizationsUser.add_user_to_organization(mail_user, mail_team)
      User.authenticate!(user: mail_user)
    end

    context "when we are a member of the mail team and a root task exists for the appeal" do
      let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal).becomes(RootTask) }
      let(:instructions) { "Some instructions for how to complete the task" }

      it "should allow us to assign a mail task to a user" do
        visit "/queue/appeals/#{appeal.uuid}"

        find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click

        find(".Select-control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
        find("div", class: "Select-option", text: COPY::FOIA_REQUEST_MAIL_TASK_LABEL).click

        fill_in("taskInstructions", with: instructions)
        find("button", text: "Submit").click

        success_msg = format(COPY::MAIL_TASK_CREATION_SUCCESS_MESSAGE, COPY::FOIA_REQUEST_MAIL_TASK_LABEL)
        expect(page).to have_content(success_msg)
        expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}")

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(FoiaRequestMailTask)
        expect(mail_task.assigned_to).to eq(MailTeam.singleton)
        expect(mail_task.children.length).to eq(1)

        child_task = mail_task.children[0]
        expect(child_task.class).to eq(FoiaRequestMailTask)
        expect(child_task.assigned_to).to eq(PrivacyTeam.singleton)
        expect(child_task.children.length).to eq(0)
      end
    end

    context "when there is no active root task for the appeal" do
      let!(:root_task) { FactoryBot.create(:root_task, :completed, appeal: appeal) }

      it "should allow us to assign a mail task to a user" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to_not have_content(COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
      end
    end
  end

  describe "Organizational queue page" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:organization_user) { FactoryBot.create(:user) }

    let(:unassigned_count) { 8 }
    let(:assigned_count) { 12 }

    before do
      OrganizationsUser.add_user_to_organization(organization_user, organization)
      User.authenticate!(user: organization_user)
      FactoryBot.create_list(:generic_task, unassigned_count, :in_progress, assigned_to: organization)
      FactoryBot.create_list(:generic_task, assigned_count, :on_hold, assigned_to: organization)
      visit(organization.path)
    end

    it "shows the right organization name" do
      expect(page).to have_content(organization.name)
    end

    it "shows tabs on the queue page" do
      expect(page).to have_content(
        format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, unassigned_count)
      )
      expect(page).to have_content(
        format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, assigned_count)
      )
      expect(page).to have_content(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
    end

    it "shows the right number of cases in each tab" do
      # Unassigned tab
      expect(page).to have_content(
        format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name)
      )
      expect(find("tbody").find_all("tr").length).to eq(unassigned_count)

      # Assigned tab
      find("button", text: format(
        COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, assigned_count
      )).click
      expect(page).to have_content(
        format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, organization.name)
      )
      expect(find("tbody").find_all("tr").length).to eq(assigned_count)
    end

    it "shows queue switcher dropdown" do
      expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)
    end
  end

  describe "VLJ support staff task action" do
    let!(:attorney) { FactoryBot.create(:user) }
    let!(:staff) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    let!(:vlj_support_staffer) { FactoryBot.create(:user) }
    let!(:judgeteam) { JudgeTeam.create_for_judge(attorney) }

    before do
      OrganizationsUser.add_user_to_organization(vlj_support_staffer, Colocated.singleton)
      OrganizationsUser.add_user_to_organization(vlj_support_staffer, judgeteam)
      User.authenticate!(user: vlj_support_staffer)
    end

    context "when a ColocatedTask has been assigned through the Colocated organization to an individual" do
      before do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :aoj,
                                                appeal: appeal
                                              }], attorney)
      end

      it "should be actionable" do
        visit("/queue/appeals/#{appeal.external_id}")

        find(".Select-control", text: "Select an action…").click
        find("div .Select-option", text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h[:label]).click
        find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

        expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran_full_name))
      end
    end

    it "shows queue switcher dropdown" do
      visit("/queue/")
      expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)

      find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
      expect(page).to have_content(Colocated.singleton.name)
      expect(page).to_not have_content(judgeteam.name)
    end
  end

  describe "JudgeTask" do
    let!(:judge_user) { FactoryBot.create(:user) }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge_user) }

    let!(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }

    before do
      User.authenticate!(user: judge_user)
    end

    context "when it was created from a QualityReviewTask" do
      let!(:qr_team) { QualityReview.singleton }
      let!(:qr_user) { FactoryBot.create(:user) }
      let!(:qr_relationship) { OrganizationsUser.add_user_to_organization(qr_user, qr_team) }
      let!(:qr_org_task) { QualityReviewTask.create_from_root_task(root_task) }
      let!(:qr_task_params) do
        [{
          appeal: appeal,
          parent_id: qr_org_task.id,
          assigned_to_id: qr_user.id,
          assigned_to_type: qr_user.class.name,
          assigned_by: qr_user
        }]
      end
      let!(:qr_person_task) { QualityReviewTask.create_many_from_params(qr_task_params, qr_user).first }

      let!(:judge_task_params) do
        [{
          appeal: appeal,
          parent_id: qr_person_task.id,
          assigned_to_id: judge_user.id,
          assigned_to_type: judge_user.class.name,
          assigned_by: qr_user
        }]
      end
      let!(:judge_task) { JudgeQualityReviewTask.create_many_from_params(judge_task_params, qr_user).first }

      before do
        visit("/queue/appeals/#{appeal.external_id}")

        # Add a user to the Colocated team so the task assignment will suceed.
        OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), Colocated.singleton)
      end

      it "should display an option to mark task complete" do
        expect(qr_person_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)

        find(".Select-control", text: "Select an action…").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click
        find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

        expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran_full_name))
        expect(judge_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(qr_person_task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
      end

      it "should be able to be sent to VLJ support staff" do
        # On case details page select the "Add admin action" option
        click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.label)

        # On case details page fill in the admin action
        action = Constants::CO_LOCATED_ADMIN_ACTIONS["ihp"]
        click_dropdown(text: action)
        fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Please complete this task")
        find("button", text: COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL).click

        # Expect to see a success message and have the task in the database
        expect(page).to have_content(format(COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE, "an", "action", action))
        expect(judge_task.children.length).to eq(1)
        expect(judge_task.children.first).to be_a(ColocatedTask)
      end
    end

    context "when it was created through case distribution" do
      before do
        FactoryBot.create(:ama_judge_task, appeal: appeal, assigned_to: judge_user)
        visit("/queue/appeals/#{appeal.external_id}")
      end

      it "should not display an option to mark task complete" do
        find(".Select-control", text: "Select an action…").click
        expect(page).to_not have_content(Constants.TASK_ACTIONS.MARK_COMPLETE.label)
      end
    end

    context "judge user's queue table view" do
      let!(:caseflow_review_task) { FactoryBot.create(:ama_judge_decision_review_task, assigned_to: judge_user) }
      let!(:legacy_review_task) do
        FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case, :assigned, user: judge_user))
      end

      it "should display both legacy and caseflow review tasks" do
        visit("/queue")
        expect(page).to have_content(format(COPY::JUDGE_CASE_REVIEW_TABLE_TITLE, 2))
      end
    end
  end
end
