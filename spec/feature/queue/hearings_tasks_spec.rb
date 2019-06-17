# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Hearings tasks workflows" do
  let(:user) { FactoryBot.create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(user, HearingsManagement.singleton)
    User.authenticate!(user: user)
  end

  describe "Postponing a NoShowHearingTask" do
    let(:veteran) { FactoryBot.create(:veteran, first_name: "Semka", last_name: "Venturini", file_number: 800_888_002) }
    let(:appeal) { FactoryBot.create(:appeal, :hearing_docket, veteran_file_number: veteran.file_number) }
    let(:veteran_link_text) { "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})" }
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
      expect(distribution_task.children.open.count).to eq(1)

      visit("/queue/appeals/#{appeal.uuid}")
      click_dropdown(text: Constants.TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.label)
      click_on(COPY::MODAL_SUBMIT_BUTTON)

      expect(page).to have_content("Success")

      expect(distribution_task.children.count).to eq(2)
      expect(distribution_task.children.open.count).to eq(1)

      new_parent_hearing_task = distribution_task.children.open.first
      expect(new_parent_hearing_task).to be_a(HearingTask)
      expect(new_parent_hearing_task.children.first).to be_a(ScheduleHearingTask)

      expect(distribution_task.ready_for_distribution?).to eq(false)
    end

    context "with a hearing and a hearing admin member" do
      let(:hearing_day) { FactoryBot.create(:hearing_day) }
      let(:hearing) { FactoryBot.create(:hearing, appeal: appeal, hearing_day: hearing_day) }
      let!(:association) do
        FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: parent_hearing_task)
      end
      let(:admin_full_name) { "Zagorka Hrenic" }
      let(:hearing_admin_user) { FactoryBot.create(:user, full_name: admin_full_name, station_id: 101) }
      let(:instructions_text) { "This is why I want a hearing disposition change!" }

      before do
        OrganizationsUser.add_user_to_organization(hearing_admin_user, HearingAdmin.singleton)
      end

      describe "requesting a hearing disposition change" do
        it "closes disposition task and children and creates a new change hearing dispositiont ask" do
          step "visit the case details page and submit a request for hearing disposition change" do
            visit("/queue/appeals/#{appeal.uuid}")
            click_dropdown(text: Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.label)
            fill_in "Notes", with: instructions_text
            click_button "Submit"
            expect(page).to have_content(
              format(COPY::CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteran_full_name)
            )
          end

          step "log in as a hearing administrator and verify that the task is in the org queue" do
            User.authenticate!(user: hearing_admin_user)
            visit "/organizations/#{HearingAdmin.singleton.url}"
            click_on veteran_link_text
            expect(page).to have_content(ChangeHearingDispositionTask.last.label)
          end

          step "verify task instructions and submit a new disposition" do
            schedule_row = find("dd", text: ChangeHearingDispositionTask.last.label).find(:xpath, "ancestor::tr")
            schedule_row.find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
            expect(schedule_row).to have_content(instructions_text)
            click_dropdown(prompt: "Select an action", text: "Change hearing disposition")
            click_dropdown({ prompt: "Select", text: "Postponed" }, find(".cf-modal-body"))
            fill_in "Notes", with: "I'm changing this to postponed."
            click_button("Submit")
            expect(page).to have_content("Successfully changed hearing disposition to Postponed")
          end
        end
      end

      describe "Bulk assign hearing tasks" do
        def fill_in_and_submit_bulk_assign_modal
          options = find_all("option")
          assign_to = options[2]
          assign_to.click
          task_type = options[8]
          task_type.click
          number_of_tasks = options[10]
          number_of_tasks.click
          submit = all("button", text: "Assign Tasks")[0]
          submit.click
        end

        it "is able to bulk assign tasks for the hearing management org" do
          3.times do
            FactoryBot.create(:no_show_hearing_task)
          end
          success_msg = "You have bulk assigned 4 No Show Hearing Task task(s)"
          visit("/organizations/hearings-management")
          click_button(text: "Assign Tasks")
          fill_in_and_submit_bulk_assign_modal
          expect(page).to have_content(success_msg)
          expect(page).to have_content("Assigned (4)")
        end
      end
    end
  end

  describe "Completing a NoShowHearingTask" do
    def mark_complete_and_verify_status(appeal, page, task)
      visit("/queue/appeals/#{appeal.external_id}")
      click_dropdown(text: Constants.TASK_ACTIONS.MARK_NO_SHOW_HEARING_COMPLETE.label)
      click_on(COPY::MARK_TASK_COMPLETE_BUTTON)

      expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran_full_name))

      expect(task.reload.status).to eq(Constants.TASK_STATUSES.completed)
    end

    let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:distribution_task) { FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task) }
    let(:parent_hearing_task) { FactoryBot.create(:hearing_task, parent: hearing_task_parent, appeal: appeal) }
    let!(:completed_scheduling_task) do
      FactoryBot.create(:schedule_hearing_task, :completed, parent: parent_hearing_task, appeal: appeal)
    end
    let(:disposition_task) { FactoryBot.create(:disposition_task, parent: parent_hearing_task, appeal: appeal) }
    let!(:no_show_hearing_task) do
      FactoryBot.create(:no_show_hearing_task, parent: disposition_task, appeal: appeal)
    end

    context "when the appeal is a LegacyAppeal" do
      let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
      let(:hearing_task_parent) { root_task }

      context "when the appellant is represented by a VSO" do
        before do
          FactoryBot.create(:vso)
          allow_any_instance_of(LegacyAppeal).to receive(:representatives) { Representative.all }
        end

        it "marks all Caseflow tasks complete and sets the VACOLS location correctly" do
          caseflow_task_count_before = Task.count

          mark_complete_and_verify_status(appeal, page, no_show_hearing_task)

          expect(Task.count).to eq(caseflow_task_count_before)
          expect(Task.open.where.not(type: RootTask.name).count).to eq(0)

          # Re-find the appeal so we re-fetch information from VACOLS.
          refreshed_appeal = LegacyAppeal.find(appeal.id)
          expect(refreshed_appeal.location_code).to eq(LegacyAppeal::LOCATION_CODES[:service_organization])
        end
      end

      context "when the appellant is not represented by a VSO" do
        it "marks all Caseflow tasks complete and sets the VACOLS location correctly" do
          caseflow_task_count_before = Task.count

          mark_complete_and_verify_status(appeal, page, no_show_hearing_task)

          expect(Task.count).to eq(caseflow_task_count_before)
          expect(Task.open.where.not(type: RootTask.name).count).to eq(0)

          # Re-find the appeal so we re-fetch information from VACOLS.
          refreshed_appeal = LegacyAppeal.find(appeal.id)
          expect(refreshed_appeal.location_code).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
        end
      end
    end

    context "when the appeal is an AMA Appeal" do
      let(:hearing_task_parent) { distribution_task }

      context "when the appellant is represented by a VSO" do
        before do
          FactoryBot.create(:vso)
          allow_any_instance_of(Appeal).to receive(:representatives) { Representative.all }
        end

        context "when the VSO is not supposed to write an IHP for this appeal" do
          before { allow_any_instance_of(Representative).to receive(:should_write_ihp?) { false } }

          it "marks the case ready for distribution" do
            mark_complete_and_verify_status(appeal, page, no_show_hearing_task)

            # DispositionTask has been closed and no IHP tasks have been created for this appeal.
            expect(parent_hearing_task.reload.children.open.count).to eq(0)
            expect(InformalHearingPresentationTask.count).to eq(0)

            expect(distribution_task.reload.ready_for_distribution?).to eq(true)
          end
        end

        context "when the VSO is supposed to write an IHP for this appeal" do
          before { allow_any_instance_of(Representative).to receive(:should_write_ihp?) { true } }

          it "creates an IHP task as a child of the HearingTask" do
            mark_complete_and_verify_status(appeal, page, no_show_hearing_task)

            # DispositionTask has been closed but IHP task has been created for this appeal.
            expect(parent_hearing_task.parent.reload.children.open.count).to eq(1)
            expect(parent_hearing_task.parent.children.open.first).to be_a(InformalHearingPresentationTask)

            expect(distribution_task.reload.ready_for_distribution?).to eq(false)
          end
        end
      end

      context "when the appellant is not represented by a VSO" do
        it "marks the case ready for distribution" do
          mark_complete_and_verify_status(appeal, page, no_show_hearing_task)

          # DispositionTask has been closed and no IHP tasks have been created for this appeal.
          expect(parent_hearing_task.reload.children.open.count).to eq(0)
          expect(InformalHearingPresentationTask.count).to eq(0)

          expect(distribution_task.reload.ready_for_distribution?).to eq(true)
        end
      end
    end
  end
end
