# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Task queue", :all_dbs do
  let!(:vlj_support_staffer) { create(:user) }

  before { OrganizationsUser.add_user_to_organization(vlj_support_staffer, Colocated.singleton) }

  context "attorney user with assigned tasks" do
    let(:attorney_user) { create(:user) }

    let!(:attorney_task) do
      create(
        :ama_attorney_task,
        :on_hold,
        assigned_to: attorney_user,
        placed_on_hold_at: 2.days.ago
      )
    end

    let!(:attorney_task_new_docs) do
      create(
        :ama_attorney_task,
        :on_hold,
        assigned_to: attorney_user,
        placed_on_hold_at: 4.days.ago,
        appeal: attorney_task.appeal
      )
    end

    let!(:colocated_task) do
      create(
        :ama_colocated_task,
        assigned_by: attorney_user,
        assigned_at: 2.days.ago,
        appeal: create(:appeal)
      )
    end

    let!(:colocated_task_new_docs) do
      create(
        :ama_colocated_task,
        assigned_by: attorney_user,
        assigned_at: 4.days.ago,
        appeal: attorney_task.appeal
      )
    end

    let!(:paper_appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: attorney_user,
          folder: build(:folder, :paper_case)
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
          create(
            :document,
            type: t,
            upload_date: 3.days.ago,
            file_number: attorney_task.appeal.veteran_file_number
          )
        end
      end

      let!(:more_documents) do
        ["NOD", "BVA Decision", "SSOC"].map do |t|
          create(
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
          create(
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
      docket_number_column_header = page.find(:xpath, "//thead/tr/th[4]/span/span[1]")
      docket_number_column_header.click
      docket_number_column_vals = page.find_all(:xpath, "//tbody/tr/td[5]/span[3]")
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
      let(:organization) { create(:organization) }

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
      v = create(:vso)
      Vso.find(v.id)
    end
    let(:vso_employee) { create(:user, :vso_role) }
    let!(:vso_task) { create(:ama_vso_task, :in_progress, assigned_to: vso) }
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
    let(:vso_employee) { create(:user, roles: ["VSO"]) }
    let(:vso) { create(:vso) }

    let(:unassigned_count) { 3 }
    let(:assigned_count) { 7 }
    let(:tracking_task_count) { 14 }

    before do
      create_list(:informal_hearing_presentation_task, unassigned_count, :in_progress, assigned_to: vso)
      create_list(:informal_hearing_presentation_task, assigned_count, :on_hold, assigned_to: vso)
      create_list(:track_veteran_task, tracking_task_count, assigned_to: vso)

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
        find("button", text: format(COPY::TRACKING_TASKS_TAB_TITLE, assigned_count)).click
        expect(page).to have_content(format(COPY::TRACKING_TASKS_TAB_DESCRIPTION, vso.name))
        expect(find("tbody").find_all("tr").length).to eq(tracking_task_count)
      end
    end
  end

  context "Field VSO team queue" do
    let(:vso_employee) { create(:user, roles: ["VSO"]) }
    let(:vso) { create(:field_vso) }

    let(:tracking_task_count) { 8 }

    before do
      create_list(:track_veteran_task, tracking_task_count, assigned_to: vso)

      allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
      User.authenticate!(user: vso_employee)
      visit(vso.path)
    end

    it "displays tracking tasks in single table" do
      step("does not show tabs since field VSOs only have 1 tab") do
        expect(page).to_not have_content(COPY::TRACKING_TASKS_TAB_TITLE)
      end

      step("shows tab description and correct number of tasks") do
        expect(page).to have_content(format(COPY::TRACKING_TASKS_TAB_DESCRIPTION, vso.name))
        expect(find("tbody").find_all("tr").length).to eq(tracking_task_count)
      end
    end
  end

  describe "Creating a mail task" do
    let(:mail_user) { create(:user) }
    let(:mail_team) { MailTeam.singleton }
    let(:appeal) { root_task.appeal }
    let(:instructions) { "Some instructions for how to complete the task" }

    let!(:pulac_user) do
      create(:user)
    end

    let!(:lit_support_team) do
      LitigationSupport.singleton
    end

    before do
      OrganizationsUser.add_user_to_organization(mail_user, mail_team)
      OrganizationsUser.add_user_to_organization(mail_user, lit_support_team)
      OrganizationsUser.add_user_to_organization(pulac_user, PulacCerullo.singleton)
      User.authenticate!(user: mail_user)
    end

    def validate_pulac_cerullo_tasks_created(task_class, label)
      visit "/queue/appeals/#{appeal.uuid}"
      find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click

      find(".Select-control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
      find("div", class: "Select-option", text: label).click

      fill_in("taskInstructions", with: instructions)
      find("button", text: "Submit").click

      success_msg = format(COPY::MAIL_TASK_CREATION_SUCCESS_MESSAGE, label)
      expect(page).to have_content(success_msg)
      expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}")
      visit "/queue/appeals/#{appeal.uuid}"

      click_dropdown(text: Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.label)
      click_button(text: "Submit")

      mail_task = root_task.reload.children[0]
      expect(mail_task.class).to eq(task_class)
      expect(mail_task.assigned_to).to eq(MailTeam.singleton)
      expect(mail_task.children.length).to eq(1)
      sleep 1
      child_task = mail_task.children[0]

      pulac_cerullo_task = child_task.children[0]
      pulac_cerullo_user_task = pulac_cerullo_task.children[0]
      expect(child_task.class).to eq(task_class)
      expect(pulac_cerullo_task.type).to eq("PulacCerulloTask")
      expect(pulac_cerullo_task.assigned_to.is_a?(Organization)).to eq(true)
      expect(pulac_cerullo_task.assigned_to.class).to eq(PulacCerullo)
      expect(pulac_cerullo_user_task.assigned_to).to eq(pulac_user)

      User.unauthenticate!
      User.authenticate!(user: pulac_user)
      visit "/queue"
      expect(page).to have_content("Assigned (1)")
      expect(page).to have_content(appeal.veteran_file_number)
    end

    context "when we are a member of the mail team and a root task exists for the appeal" do
      let!(:root_task) { create(:root_task) }
      it "should allow us to assign a mail task to a user" do
        visit "/queue/appeals/#{appeal.uuid}"

        find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click

        find(".Select-control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
        find("div", class: "Select-option", text: COPY::AOD_MOTION_MAIL_TASK_LABEL).click

        fill_in("taskInstructions", with: instructions)
        find("button", text: "Submit").click

        success_msg = format(COPY::MAIL_TASK_CREATION_SUCCESS_MESSAGE, COPY::AOD_MOTION_MAIL_TASK_LABEL)
        expect(page).to have_content(success_msg)
        expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}")

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(AodMotionMailTask)
        expect(mail_task.assigned_to).to eq(MailTeam.singleton)
        expect(mail_task.children.length).to eq(1)

        child_task = mail_task.children[0]
        expect(child_task.class).to eq(AodMotionMailTask)
        expect(child_task.assigned_to).to eq(AodTeam.singleton)
        expect(child_task.children.length).to eq(0)
      end
    end

    context "when a ClearAndUnmistakeableErrorMailTask task is routed to Pulac Cerullo" do
      let!(:root_task) { create(:root_task) }
      it "creates two child tasks: one Pulac Cerullo Task, and a child of that task " \
        "assigned to the first user in the Pulac Cerullo org" do
        validate_pulac_cerullo_tasks_created(
          ClearAndUnmistakeableErrorMailTask, COPY::CLEAR_AND_UNMISTAKABLE_ERROR_MAIL_TASK_LABEL
        )
      end
    end

    context "when a ReconsiderationMotionMailTask task is routed to Pulac Cerullo" do
      let!(:root_task) { create(:root_task) }
      it "creates two child tasks: one Pulac Cerullo Task, and a child of that task " \
        "assigned to the first user in the Pulac Cerullo org" do
        validate_pulac_cerullo_tasks_created(
          ReconsiderationMotionMailTask, COPY::RECONSIDERATION_MOTION_MAIL_TASK_LABEL
        )
      end
    end

    context "when a VacateMotionMailTask task is routed to Pulac Cerullo" do
      let!(:root_task) { create(:root_task) }
      it "creates two child tasks: one Pulac Cerullo Task, and a child of that task " \
        "assigned to the first user in the Pulac Cerullo org" do
        validate_pulac_cerullo_tasks_created(VacateMotionMailTask, COPY::VACATE_MOTION_MAIL_TASK_LABEL)
      end
    end

    context "when there is no active root task for the appeal" do
      let!(:root_task) { create(:root_task, :completed) }

      it "should allow us to create a mail task" do
        visit "/queue/appeals/#{appeal.uuid}"

        find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click

        find(".Select-control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
        find("div", class: "Select-option", text: COPY::AOD_MOTION_MAIL_TASK_LABEL).click

        fill_in("taskInstructions", with: instructions)
        find("button", text: "Submit").click

        success_msg = format(COPY::MAIL_TASK_CREATION_SUCCESS_MESSAGE, COPY::AOD_MOTION_MAIL_TASK_LABEL)
        expect(page).to have_content(success_msg)
        expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}")

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(AodMotionMailTask)
        expect(mail_task.assigned_to).to eq(MailTeam.singleton)
        expect(mail_task.children.length).to eq(1)

        child_task = mail_task.children[0]
        expect(child_task.class).to eq(AodMotionMailTask)
        expect(child_task.assigned_to).to eq(AodTeam.singleton)
        expect(child_task.children.length).to eq(0)
      end
    end
  end

  describe "Organizational queue page" do
    let(:organization) { create(:organization) }
    let(:organization_user) { create(:user) }

    let(:unassigned_count) { 8 }
    let(:assigned_count) { 12 }

    before do
      OrganizationsUser.add_user_to_organization(organization_user, organization)
      User.authenticate!(user: organization_user)
      create_list(:generic_task, unassigned_count, :in_progress, assigned_to: organization)
      create_list(:generic_task, assigned_count, :on_hold, assigned_to: organization)
    end

    context "when not using pagination" do
      before do
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
        expect(page).to_not have_content(COPY::TRACKING_TASKS_TAB_TITLE)
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
            vacols_case = create(:case)
            legacy_appeal = create(:legacy_appeal, vacols_case: vacols_case)
            vacols_case.destroy!
            create(:generic_task, :in_progress, appeal: legacy_appeal, assigned_to: organization)
          end
        end

        it "loads the task queue successfully" do
          # Re-navigate to the organization queue so we pick up the above task creation.
          visit(organization.path)

          tasks.each { |t| expect(page).to have_content(t.appeal.veteran_file_number) }
          expect(page).to_not have_content("Information cannot be found")
        end
      end

      context "when filtering tasks" do
        let(:translation_task_count) { unassigned_count / 2 }

        before do
          Task.active.where(assigned_to_type: Organization.name, assigned_to_id: organization.id)
            .take(translation_task_count).each { |task| task.update!(type: TranslationTask.name) }
          visit(organization.path)
        end

        it "shows the correct filters" do
          page.find_all("path.unselected-filter-icon-inner").first.click
          expect(page).to have_content("#{GenericTask.label.humanize} (#{unassigned_count / 2})")
          expect(page).to have_content("#{TranslationTask.label.humanize} (#{translation_task_count})")
        end

        it "filters tasks correctly" do
          expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
          page.find_all("path.unselected-filter-icon-inner").first.click
          page.find("label", text: "#{TranslationTask.label.humanize} (#{translation_task_count})").click
          expect(find("tbody").find_all("tr").length).to eq(translation_task_count)
        end
      end
    end

    context "when pagination is enabled" do
      let(:on_hold_count) { assigned_count / 2 }

      before do
        allow_any_instance_of(QueueConfig).to receive(:use_task_pages_api?).with(organization_user).and_return(true)
        FeatureToggle.enable!(:use_task_pages_api)
        Task.on_hold.where(assigned_to_type: Organization.name, assigned_to_id: organization.id)
          .each_with_index do |task, idx|
            child_task = create(:generic_task, parent_id: task.id)
            child_task.update!(status: Constants.TASK_STATUSES.on_hold) if idx < on_hold_count
          end
      end

      it "shows the on hold tab" do
        visit(organization.path)
        expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, assigned_count / 2))
        expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, on_hold_count))
      end

      context "displays the correct filters" do
        let(:translation_task_count) { unassigned_count / 2 }

        before do
          Task.active.where(assigned_to_type: Organization.name, assigned_to_id: organization.id)
            .take(translation_task_count).each { |task| task.update!(type: TranslationTask.name) }
        end

        it "shows the correct filters" do
          visit(organization.path)
          expect(page).to have_content(
            format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name)
          )
          page.find_all("path.unselected-filter-icon-inner").first.click
          expect(page).to have_content("#{GenericTask.label} (#{unassigned_count / 2})")
          expect(page).to have_content("#{TranslationTask.label} (#{unassigned_count / 2})")
        end
      end
    end
  end

  describe "VLJ support staff task action" do
    let!(:attorney) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    let!(:judgeteam) { JudgeTeam.create_for_judge(attorney) }

    before do
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
        find("div .Select-option", text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_JUDGE.label).click
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

  describe "Hearing management schedule hearing action" do
    let(:attorney) { create(:user) }
    let(:vacols_case) { create(:case) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: vacols_case) }
    let!(:hearings_management_user) { create(:user) }

    before do
      OrganizationsUser.add_user_to_organization(hearings_management_user, HearingsManagement.singleton)
      User.authenticate!(user: hearings_management_user)
    end

    context "when a ColocatedTask has been assigned through the Colocated organization to an individual" do
      before do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :schedule_hearing,
                                                appeal: appeal,
                                                parent: RootTask.find_or_create_by!(appeal: appeal)
                                              }], attorney)
      end

      it "the location is updated to caseflow when a user assigns a colocated task back to the hearing team" do
        visit("/queue/appeals/#{appeal.external_id}")
        find(".Select-control", text: "Select an action…").click
        expect(page).to have_content(Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h[:label])
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.label).click
        find("button", text: "Send case").click
        expect(page).to have_content("Bob Smith's case has been sent to the Confirm schedule hearing team")
        expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:schedule_hearing]
      end

      it "the case should be returned in the attorneys queue when canceled" do
        visit("/queue/appeals/#{appeal.external_id}")
        find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        expect(page).to have_content(Constants.TASK_ACTIONS.CANCEL_TASK.label)
        expect(page).to have_content(Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.label)
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CANCEL_TASK.label).click
        find("button", text: COPY::MODAL_SUBMIT_BUTTON).click
        expect(page).to have_content("Task for Bob Smith's case has been cancelled")
        User.authenticate!(user: attorney)
        visit("/queue")
        expect(page).to have_content(appeal.veteran_file_number)
      end

      context "for an ama appeal" do
        let(:appeal) { create(:appeal) }

        it "creates a schedule hearing task when a user assigns a colocated task back to the hearing team" do
          visit("/queue/appeals/#{appeal.external_id}")
          find(".Select-control", text: "Select an action…").click
          expect(page).to have_content(Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h[:label])
          find("div", class: "Select-option", text: Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.label).click
          find("button", text: "Send case").click
          expect(page).to have_content("Bob Smith's case has been sent to the Confirm schedule hearing team")
          expect(appeal.tasks.pluck(:type)).to include(ScheduleHearingTask.name, HearingTask.name)
        end
      end
    end
  end

  describe "JudgeTask" do
    let!(:judge_user) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge_user) }
    let!(:appeal) do
      create(
        :appeal,
        number_of_claimants: 1,
        request_issues: build_list(
          :request_issue, 1,
          contested_issue_description: "Tinnitus"
        )
      )
    end
    let!(:decision_issue) { create(:decision_issue, decision_review: appeal, request_issues: appeal.request_issues) }

    let(:root_task) { create(:root_task, appeal: appeal) }

    before do
      User.authenticate!(user: judge_user)
    end

    context "when it was created from a QualityReviewTask" do
      let!(:qr_team) { QualityReview.singleton }
      let!(:qr_user) { create(:user) }
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
        OrganizationsUser.add_user_to_organization(create(:user), Colocated.singleton)
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

    context "when it was created from a BvaDispatchTask" do
      let!(:bva_dispatch_user) { create(:user) }
      let!(:bva_dispatch_relationship) do
        OrganizationsUser.add_user_to_organization(bva_dispatch_user, BvaDispatch.singleton)
      end
      let!(:attorney_user) { create(:user) }
      let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }

      let!(:attorney_judge_relationship) do
        OrganizationsUser.add_user_to_organization(attorney_user, judge_team)
      end
      let!(:orig_judge_task) do
        create(
          :ama_judge_decision_review_task,
          :on_hold,
          assigned_to: judge_user,
          appeal: appeal,
          parent: root_task
        )
      end

      let!(:orig_atty_task) do
        create(
          :ama_attorney_task,
          :completed,
          assigned_to: attorney_user,
          assigned_by: judge_user,
          parent: orig_judge_task,
          appeal: appeal
        )
      end

      let!(:judge_task_done) do
        orig_judge_task.update!(status: Constants.TASK_STATUSES.completed)
      end

      let!(:bva_dispatch_org_task) { BvaDispatchTask.create_from_root_task(root_task) }
      let!(:bva_dispatch_task_params) do
        [{
          appeal: appeal,
          parent_id: bva_dispatch_org_task.id,
          assigned_to_id: bva_dispatch_user.id,
          assigned_to_type: bva_dispatch_user.class.name,
          assigned_by: bva_dispatch_user
        }]
      end

      let!(:bva_dispatch_person_task) do
        bva_dispatch_org_task.children.first
      end

      let!(:judge_task_params) do
        [{
          appeal: appeal,
          parent_id: bva_dispatch_person_task.id,
          assigned_to_id: judge_user.id,
          assigned_to_type: judge_user.class.name
        }]
      end
      let!(:judge_task) do
        JudgeDispatchReturnTask.create_many_from_params(judge_task_params, bva_dispatch_user).first
      end

      before do
        visit("/queue/appeals/#{appeal.external_id}")

        # Add a user to the Colocated team so the task assignment will suceed.
        OrganizationsUser.add_user_to_organization(create(:user), Colocated.singleton)
      end

      it "should display an option of Ready for Dispatch" do
        expect(bva_dispatch_person_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)

        find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label).click

        expect(page).to have_content(COPY::DECISION_ISSUE_PAGE_TITLE)
        click_on "Continue"

        expect(page).to have_content("Evaluate Decision")
        find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
        text_to_click = "5 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['outstanding']}"
        find("label", text: text_to_click).click
        find("#issues_are_not_addressed", visible: false).sibling("label").click
        dummy_note = generate_words 5
        fill_in "additional-factors", with: dummy_note
        expect(page).to have_content(dummy_note[0..5])
        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

        expect(judge_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(bva_dispatch_person_task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
      end

      it "should display an option to Return to Attorney" do
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                       text: Constants.TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.label)
        expect(dropdown_selected_value(find(".cf-modal-body"))).to eq attorney_user.full_name
        fill_in "taskInstructions", with: "Please fix this"

        click_on COPY::MODAL_SUBMIT_BUTTON

        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % attorney_user.full_name)

        expect(judge_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(judge_task.children.first).to be_a(AttorneyDispatchReturnTask)
        expect(judge_task.children.first.status).to eq(Constants.TASK_STATUSES.assigned)
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
        create(:ama_judge_task, appeal: appeal, assigned_to: judge_user)
        visit("/queue/appeals/#{appeal.external_id}")
      end

      it "should not display an option to mark task complete" do
        find(".Select-control", text: "Select an action…").click
        expect(page).to_not have_content(Constants.TASK_ACTIONS.MARK_COMPLETE.label)
      end
    end

    context "judge user's queue table view" do
      let(:root_task) { create(:root_task) }
      let!(:caseflow_review_task) do
        create(
          :ama_judge_decision_review_task,
          assigned_to: judge_user,
          parent: root_task,
          appeal: root_task.appeal
        )
      end
      let!(:legacy_review_task) do
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: judge_user))
      end

      it "should display both legacy and caseflow review tasks" do
        visit("/queue")
        expect(page).to have_content(format(COPY::JUDGE_CASE_REVIEW_TABLE_TITLE, 2))
      end

      it "should be able to add admin actions from case details" do
        OrganizationsUser.add_user_to_organization(create(:user), Colocated.singleton)
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
      let(:user) { create(:user) }
      let(:root_task) { create(:root_task) }
      let(:appeal) { root_task.appeal }
      let(:task) { create(:generic_task, assigned_to: user) }

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
      let(:user) { create(:user) }
      let(:vacols_case) { create(:case) }
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let!(:task) { create(:generic_task, appeal: legacy_appeal, assigned_to: user) }

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

  describe "a task with a child TimedHoldTask" do
    let(:user) { create(:user) }
    let(:veteran) { create(:veteran, first_name: "Julita", last_name: "Van Sant", file_number: 201_905_061) }
    let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
    let(:veteran_link_text) { "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})" }
    let!(:root_task) { create(:root_task, appeal: appeal) }
    let!(:hearing_task) { create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) do
      create(:assign_hearing_disposition_task, parent: hearing_task, appeal: appeal)
    end
    let!(:transcription_task) do
      create(:transcription_task, parent: disposition_task, appeal: appeal, assigned_to: user)
    end
    let(:days_on_hold) { 18 }
    let!(:timed_hold_task) do
      TimedHoldTask.create_from_parent(transcription_task, days_on_hold: days_on_hold)
    end

    before do
      OrganizationsUser.add_user_to_organization(user, TranscriptionTeam.singleton)
      User.authenticate!(user: user)
    end

    it "can remove the hold from the task" do
      step "visit queue and go to the case details page" do
        visit "/queue"
        click_on "On hold (1)"
        click_on veteran_link_text
        expect(page).to have_content "Currently active tasks"
      end

      schedule_row = find("dd", text: TranscriptionTask.last.label).find(:xpath, "ancestor::tr")

      step "select the end timed hold option from the action dropdown" do
        expect(schedule_row).to have_content("DAYS ON HOLD 0 of #{days_on_hold}", normalize_ws: true)
        available_options = click_dropdown({ text: Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h[:label] }, schedule_row)
        # the dropdown has the default options in addition to the end timed hold action
        default_options = transcription_task.available_actions_unwrapper(user).map { |option| option[:label] }
        expect(available_options.count).to eq default_options.count
        expect(available_options).to include(*default_options)
      end

      step "submit the end timed hold form" do
        click_button "Submit"
        expect(page).to have_content "Success!"
        expect(schedule_row).to have_content("DAYS WAITING 0", normalize_ws: true)
      end
    end

    it "hold is removed when the parent task is updated" do
      step "visit queue and go to the case details page" do
        visit "/queue"
        click_on "On hold (1)"
        click_on veteran_link_text
        expect(page).to have_content "Currently active tasks"
      end

      schedule_row = find("dd", text: TranscriptionTask.last.label).find(:xpath, "ancestor::tr")

      step "select and submit the complete transcription action" do
        click_dropdown({ text: Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h[:label] }, schedule_row)
        expect(page).to have_content "Mark as complete"
        click_button "Mark complete"
        expect(page).to have_content "#{appeal.veteran_full_name}'s case has been marked complete"
      end

      step "verify that the transcription task is completed" do
        click_on "Completed"
        click_on veteran_link_text
        expect(page).to have_content("Currently active tasks")
        expect(page).to have_content("No active tasks")
      end

      step "verify that the associated TimedHoldTask has been canceled" do
        expect(timed_hold_task.reload.open?).to be_falsey
      end
    end
  end
end
