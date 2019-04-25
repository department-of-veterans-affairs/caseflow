# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Task queue" do
  context "attorney user with assigned tasks" do
    let(:attorney_user) { FactoryBot.create(:user) }

    let!(:attorney_task) do
      FactoryBot.create(
        :ama_attorney_task,
        :on_hold,
        assigned_to: attorney_user,
        placed_on_hold_at: 2.days.ago
      )
    end

    let!(:attorney_task_new_docs) do
      FactoryBot.create(
        :ama_attorney_task,
        :on_hold,
        assigned_to: attorney_user,
        placed_on_hold_at: 4.days.ago,
        appeal: attorney_task.appeal
      )
    end

    let!(:colocated_task) do
      FactoryBot.create(
        :ama_colocated_task,
        assigned_by: attorney_user,
        assigned_at: 2.days.ago,
        appeal: create(:appeal)
      )
    end

    let!(:colocated_task_new_docs) do
      FactoryBot.create(
        :ama_colocated_task,
        assigned_by: attorney_user,
        assigned_at: 4.days.ago,
        appeal: attorney_task.appeal
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
    let(:attorney_on_hold_task_count) { Task.where(status: :on_hold, assigned_to: attorney_user).count }

    before do
      User.authenticate!(user: attorney_user)
      visit "/queue"
    end

    context "the on-hold task is attached to an appeal with documents" do
      let!(:documents) do
        ["NOD", "BVA Decision", "SSOC"].map do |t|
          FactoryBot.create(
            :document,
            type: t,
            upload_date: 3.days.ago,
            file_number: attorney_task.appeal.veteran_file_number
          )
        end
      end

      let!(:more_documents) do
        ["NOD", "BVA Decision", "SSOC"].map do |t|
          FactoryBot.create(
            :document,
            type: t,
            upload_date: 3.days.ago,
            file_number: colocated_task.appeal.veteran_file_number
          )
        end
      end

      it "shows the correct number of tasks on hold" do
        expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, attorney_on_hold_task_count))
      end
    end

    it "displays a table with a row for each case assigned to the attorney" do
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)
    end

    context "hearings" do
      context "if a task has a hearing" do
        let!(:attorney_task_with_hearing) do
          FactoryBot.create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user
          )
        end

        let!(:hearing) { create(:hearing, appeal: attorney_task_with_hearing.appeal, disposition: "held") }

        before do
          visit "/queue"
        end

        it "shows the hearing badge" do
          expect(page).to have_selector(".cf-hearing-badge")
          expect(find(".cf-hearing-badge")).to have_content("H")
        end
      end

      context "if no tasks have hearings" do
        it "does not show the hearing badge" do
          expect(page).not_to have_selector(".cf-hearing-badge")
        end
      end
    end

    it "supports custom sorting" do
      docket_number_column_header = page.find(:xpath, "//thead/tr/th[3]/span/span[1]")
      docket_number_column_header.click
      docket_number_column_vals = page.find_all(:xpath, "//tbody/tr/td[4]/span[3]")
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
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, attorney_on_hold_task_count))
      expect(page).to have_content(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
    end

    it "shows the right number of cases in each tab" do
      # Assigned tab
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)

      # On Hold tab
      find("button", text: format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, attorney_on_hold_task_count)).click
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION)
      expect(find("tbody").find_all("tr").length).to eq(attorney_on_hold_task_count)
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
      allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
      visit(vso.path)
    end

    it "should be able to take actions on task from VSO queue" do
      expect(page).to have_content(COPY::ORGANIZATION_QUEUE_TABLE_TITLE % vso.name)

      find_table_cell(vso_task.id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
        .click_link
      expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTION_BOX_TITLE)

      # Marking the task as complete correctly changes the task's status in the database.
      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      find("button", text: "Mark complete").click

      expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, vso_task.appeal.veteran_full_name))
      expect(Task.find(vso_task.id).status).to eq("completed")
    end
  end

  context "VSO team queue" do
    let(:vso_employee) { FactoryBot.create(:user, roles: ["VSO"]) }
    let(:vso) { FactoryBot.create(:vso) }

    let(:unassigned_count) { 3 }
    let(:assigned_count) { 7 }
    let(:tracking_task_count) { 14 }

    before do
      FactoryBot.create_list(:informal_hearing_presentation_task, unassigned_count, :in_progress, assigned_to: vso)
      FactoryBot.create_list(:informal_hearing_presentation_task, assigned_count, :on_hold, assigned_to: vso)
      FactoryBot.create_list(:track_veteran_task, tracking_task_count, assigned_to: vso)

      allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
      User.authenticate!(user: vso_employee)
      visit(vso.path)
    end

    it "shows the right number of cases in each tab" do
      step("Unassigned tab") do
        expect(page).to have_content(format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, vso.name))
        expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
      end

      step("Assigned tab") do
        find("button", text: format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, assigned_count)).click
        expect(page).to have_content(format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, vso.name))
        expect(find("tbody").find_all("tr").length).to eq(assigned_count)
      end

      step("All cases tab") do
        find("button", text: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE, assigned_count)).click
        expect(page).to have_content(format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, vso.name))
        expect(find("tbody").find_all("tr").length).to eq(tracking_task_count)
      end
    end
  end

  describe "Creating a mail task" do
    let(:mail_user) { FactoryBot.create(:user) }
    let(:mail_team) { MailTeam.singleton }
    let(:appeal) { root_task.appeal }
    let(:instructions) { "Some instructions for how to complete the task" }

    before do
      OrganizationsUser.add_user_to_organization(mail_user, mail_team)
      User.authenticate!(user: mail_user)
    end

    context "when we are a member of the mail team and a root task exists for the appeal" do
      let!(:root_task) { FactoryBot.create(:root_task) }

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
      let!(:root_task) { FactoryBot.create(:root_task, :completed) }

      it "should allow us to create a mail task" do
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

    it "does not show all cases tab for non-VSO organization" do
      expect(page).to_not have_content(COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE)
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

    context "when organization tasks include one associated with a LegacyAppeal that has been removed from VACOLS" do
      let!(:tasks) do
        Array.new(4) do
          vacols_case = FactoryBot.create(:case)
          legacy_appeal = FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
          vacols_case.destroy!
          FactoryBot.create(:generic_task, :in_progress, appeal: legacy_appeal, assigned_to: organization)
        end
      end

      it "loads the task queue successfully" do
        # Re-navigate to the organization queue so we pick up the above task creation.
        visit(organization.path)

        tasks.each { |t| expect(page).to have_content(t.appeal.veteran_file_number) }
        expect(page).to_not have_content("Information cannot be found")
      end
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
        expect(page).to have_content("Instructions:")
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
  describe "VLJ support staff schedule hearing action" do
    let(:attorney) { FactoryBot.create(:user) }
    let(:vacols_case) { create(:case) }
    let!(:staff) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:appeal) { FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: vacols_case) }
    let!(:vlj_support_staffer) { FactoryBot.create(:user) }

    before do
      OrganizationsUser.add_user_to_organization(vlj_support_staffer, Colocated.singleton)
      User.authenticate!(user: vlj_support_staffer)
    end

    context "when a ColocatedTask has been assigned through the Colocated organization to an individual" do
      before do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :schedule_hearing,
                                                appeal: appeal
                                              }], attorney)
      end

      it "the location is updated to 57 when a user assigns a colocated task back to the hearing team" do
        visit("/queue/appeals/#{appeal.external_id}")
        find(".Select-control", text: "Select an action…").click
        expect(page).to have_content(Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h[:label])
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.label).click
        find("button", text: "Send case").click
        expect(page).to have_content("Bob Smith's case has been sent to the Schedule hearing team")
        expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
      end

      it "the case should be returned in the attorneys queue when canceled" do
        visit("/queue/appeals/#{appeal.external_id}")
        find(".Select-control", text: "Select an action…").click
        expect(page).to have_content(Constants.TASK_ACTIONS.CANCEL_TASK.to_h[:label])
        expect(page).to have_content(Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h[:label])
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CANCEL_TASK.label).click
        find("button", text: "Submit").click
        expect(page).to have_content("Task for Bob Smith's case has been cancelled")
        User.authenticate!(user: attorney)
        visit("/queue")
        expect(page).to have_content(appeal.veteran_file_number)
      end
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

        # Expect to see a success message, the correct number of remaining tasks and have the task in the database
        expect(page).to have_content(format(COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE, "an", "action", action))
        expect(page).to have_content(format(COPY::JUDGE_CASE_REVIEW_TABLE_TITLE, 0))
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
      let(:root_task) { FactoryBot.create(:root_task) }
      let!(:caseflow_review_task) do
        FactoryBot.create(
          :ama_judge_decision_review_task,
          assigned_to: judge_user,
          parent: root_task,
          appeal: root_task.appeal
        )
      end
      let!(:legacy_review_task) do
        FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case, :assigned, user: judge_user))
      end

      it "should display both legacy and caseflow review tasks" do
        visit("/queue")
        expect(page).to have_content(format(COPY::JUDGE_CASE_REVIEW_TABLE_TITLE, 2))
      end

      it "should be able to add admin actions from case details" do
        OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), Colocated.singleton)
        visit("/queue")
        click_on "#{legacy_review_task.veteran_full_name} (#{legacy_review_task.sanitized_vbms_id})"
        # On case details page select the "Add admin action" option
        click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.label)

        # On case details page fill in the admin action
        action = Constants::CO_LOCATED_ADMIN_ACTIONS["ihp"]
        click_dropdown(text: action)
        fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Please complete this task")
        find("button", text: COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL).click

        # Expect to see a success message and the correct number of remaining tasks
        expect(page).to have_content(format(COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE, "an", "action", action))
        expect(page).to have_content(format(COPY::JUDGE_CASE_REVIEW_TABLE_TITLE, 1))
      end
    end
  end

  describe "GenericTask" do
    context "when it is assigned to the current user" do
      let(:user) { FactoryBot.create(:user) }
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:appeal) { root_task.appeal }
      let(:task) { FactoryBot.create(:generic_task, assigned_to: user) }

      before { User.authenticate!(user: user) }

      it "allows the user to cancel the task" do
        visit("queue/appeals/#{task.appeal.external_id}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: COPY::CANCEL_TASK_MODAL_TITLE)
        click_button("Submit")
        expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, appeal.veteran_full_name))
        expect(page.current_path).to eq("/queue")
        expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end
    end

    context "when a task is associated with a LegacyAppeal that has been removed from VACOLS" do
      let(:user) { FactoryBot.create(:user) }
      let(:vacols_case) { FactoryBot.create(:case) }
      let(:legacy_appeal) { FactoryBot.create(:legacy_appeal, vacols_case: vacols_case) }
      let!(:task) { FactoryBot.create(:generic_task, appeal: legacy_appeal, assigned_to: user) }

      before do
        vacols_case.destroy!
        User.authenticate!(user: user)
      end

      it "loads the task queue successfully" do
        visit("/queue")

        expect(page).to have_content(legacy_appeal.veteran_file_number)
        expect(page).to_not have_content("Information cannot be found")
      end
    end
  end
end
