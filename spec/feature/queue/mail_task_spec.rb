# frozen_string_literal: true

RSpec.feature "MailTasks", :postgres do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:instructions) { "instructions" }

  before do
    User.authenticate!(user: user)
    Seeds::NotificationEvents.new.seed!
  end

  describe "Assigning a mail team task to a team member" do
    context "when task is assigned to AOD team" do
      let(:root_task) { create(:root_task) }

      let(:mail_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )
      end

      let(:aod_team) { AodTeam.singleton }

      let(:aod_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: mail_team_task.id,
          assigned_to: aod_team
        )
      end

      before do
        aod_team.add_user(user)
      end

      it "successfully assigns the task to team member" do
        visit("/queue")
        visit("queue/appeals/#{aod_team_task.appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label
        click_dropdown(prompt: prompt, text: text)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, user.full_name))
        expect(page.current_path).to eq("/queue")

        new_tasks = aod_team_task.children
        expect(new_tasks.length).to eq(1)

        new_task = new_tasks.first
        expect(new_task.assigned_to).to eq(user)
      end
    end
  end

  describe "Changing a mail team task type" do
    let(:root_task) { create(:root_task) }
    let(:old_task_type) { DeathCertificateMailTask }
    let(:new_task_type) { AddressChangeMailTask }
    let(:old_instructions) { generate_words(5) }

    let(:grandparent_task) do
      old_task_type.create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )
    end

    let(:parent_task) do
      old_task_type.create!(
        appeal: grandparent_task.appeal,
        parent_id: grandparent_task.id,
        assigned_to: Colocated.singleton,
        instructions: [old_instructions]
      )
    end

    let(:vlj_support_user) { create(:user, :vlj_support_user) }

    let(:task) do
      old_task_type.create!(
        appeal: parent_task.appeal,
        parent_id: parent_task.id,
        assigned_to: vlj_support_user,
        status: Constants.TASK_STATUSES.assigned,
        instructions: [old_instructions]
      )
    end

    before do
      Colocated.singleton.add_user(user)
    end

    it "should update the task type" do
      visit "/queue/" # avoids a weird race condition
      visit "/queue/appeals/#{task.appeal.uuid}"

      # Make sure mail team tasks do not show in task snapshot
      expect(find("#currently-active-tasks").has_no_content?("ASSIGNED TO\nMail")).to eq(true)
      expect(find_all("#currently-active-tasks tr").length).to eq 1

      # Navigate to the change task type modal
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

      expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

      # Ensure all admin actions are available
      mail_tasks = MailTask.descendant_routing_options
      find(".cf-select__control", text: "Select an action type").click do
        visible_options = page.find_all(".cf-select__option")
        expect(visible_options.length).to eq mail_tasks.length
      end

      # Attempt to change task type without including instuctions.
      find("div", class: "cf-select__option", text: new_task_type.label).click
      find_button(text: COPY::CHANGE_TASK_TYPE_SUBHEAD, disabled: true)

      # Add instructions and try again
      new_instructions = generate_words(5)
      fill_in("Provide instructions and context for this change:", with: new_instructions)
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # We should see a success message but remain on the case details page
      expect(page).to have_content(
        format(
          COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
          old_task_type.label,
          new_task_type.label
        )
      )

      # Ensure the task has been updated and the assignee is unchanged
      expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
      expect(page).to have_content(format("ASSIGNED TO\nVLJ Support Staff"))
      page.find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
      expect(page).to have_content(old_instructions)
      expect(page).to have_content(new_instructions)
    end
  end

  shared_examples_for "task reassignments" do
    context "assigning to new team" do
      it "behavior of the task when assigning it to a new team" do
        page = "queue/appeals/#{appeal.uuid}"

        step "submit button starts out disabled" do
          visit(page)
          within("tr", text: "TASK", match: :first) do
            click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                           text: Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.label,
                           match: :first)
          end
          modal = find(".cf-modal-body")
          expect(modal).to have_button("Submit", disabled: true)
        end

        step "assigns to new team" do
          find(".cf-select__control", text: "Select a team", match: :first).click
          find(".cf-select__option", text: "BVA Intake").click
          fill_in("taskInstructions", with: "instructions")
          click_button("Submit")
          new_task = appeal.tasks.last
          visit(page)
          most_recent_task = find("tr", text: "TASK", match: :first)
          expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
          expect(most_recent_task).to have_content("ASSIGNED TO\nBVA Intake")
        end
      end
    end

    context "assigning to person" do
      let(:new_user) { User.create!(css_id: "NEW_USER", full_name: "John Smith", station_id: "101") }

      before do
        HearingAdmin.singleton.add_user(new_user)
      end

      it "behavior of the task when assigning it to a person" do
        page = "queue/appeals/#{appeal.uuid}"

        step "submit button starts out disabled" do
          visit(page)
          within("tr", text: "TASK", match: :first) do
            click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                           text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label,
                           match: :first)
          end
          modal = find(".cf-modal-body")
          expect(modal).to have_button("Submit", disabled: true)
        end

        step "assigns to person" do
          find(".cf-select__control", text: User.current_user.full_name).click
          find(".cf-select__option", text: new_user.full_name).click
          fill_in("taskInstructions", with: "instructions")
          click_button("Submit")
          new_task = appeal.tasks.last
          visit(page)
          most_recent_task = find("tr", text: "TASK", match: :first)
          expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
          expect(most_recent_task).to have_content("ASSIGNED TO\n#{new_user.css_id}")
        end
      end
    end
  end

  describe "Hearing Postponement Request Mail Task" do
    before do
      HearingAdmin.singleton.add_user(User.current_user)
    end
    let(:appeal) { hpr_task.appeal }
    let(:hpr_task) do
      create(:hearing_postponement_request_mail_task,
             :postponement_request_with_unscheduled_hearing, assigned_by_id: User.system_user.id)
    end
    let(:scheduled_hpr_task) do
      create(:hearing_postponement_request_mail_task,
             :postponement_request_with_scheduled_hearing, assigned_by_id: User.system_user.id)
    end
    let(:scheduled_appeal) { scheduled_hpr_task.appeal }
    let(:legacy_appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: create(:case))
    end
    let!(:legacy_hpr_task) do
      create(:hearing_postponement_request_mail_task,
             :postponement_request_with_unscheduled_hearing,
             assigned_by_id: User.system_user.id, appeal: legacy_appeal)
    end
    let(:scheduled_legacy_appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: create(:case))
    end
    let!(:scheduled_legacy_hpr_task) do
      create(:hearing_postponement_request_mail_task,
             :postponement_request_with_scheduled_hearing,
             assigned_by_id: User.system_user.id, appeal: scheduled_legacy_appeal)
    end
    let(:email) { "test@caseflow.com" }

    shared_examples_for "scheduling a hearing" do
      before do
        FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
        page = appeal.is_a?(Appeal) ? "queue/appeals/#{appeal.uuid}" : "queue/appeals/#{appeal.vacols_id}"
        visit(page)
        within("tr", text: "TASK", match: :first) do
          click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                         text: Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.label,
                         match: :first)
        end
        find(".cf-form-radio-option", text: ruling).click
        fill_in("rulingDateSelector", with: ruling_date)
        find(:css, ".cf-form-radio-option label", text: "Reschedule immediately").click
        fill_in("instructionsField", with: instructions)
        click_button("Mark as complete")

        within(:css, ".dropdown-hearingType") { click_dropdown(text: "Virtual") }
        within(:css, ".dropdown-regionalOffice") { click_dropdown(text: "Denver, CO") }
        within(:css, ".dropdown-hearingDate") { click_dropdown(index: 0) }
        find("label", text: "12:30 PM Mountain Time (US & Canada) / 2:30 PM Eastern Time (US & Canada)").click
        if has_css?("[id='Appellant Email (for these notifications only)']")
          fill_in("Appellant Email (for these notifications only)", with: email)
        else
          fill_in("Veteran Email (for these notifications only)", with: email)
        end
        click_button("Schedule")
      end

      it "gets scheduled" do
        step "Displays success message" do
          expect(page).to have_content("You have successfully")
        end

        step "sends proper notifications" do
          appeal.reload
          scheduled_payload = AppellantNotification.create_payload(appeal, "Hearing scheduled").to_json
          postpone_payload = AppellantNotification.create_payload(appeal, "Postponement of hearing").to_json
          jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
            .select { |job| job[:job] == SendNotificationJob }

          expect(jobs).to be_an(Array)
          if appeal.hearings.any? { |hearing| hearing.disposition == Constants.HEARING_DISPOSITION_TYPES.postponed }
            expect(jobs.length).to eq(2)
            expect(jobs.map { |job| job[:args][0] }).to include(postpone_payload)
            expect(jobs.map { |job| job[:args][0] }).to include(scheduled_payload)

          else
            expect(jobs.length).to eq(1)
            expect(jobs[0][:args][0]).to eq(scheduled_payload)
          end
        end
      end
    end

    context "task actions" do
      include_examples "task reassignments"
      context "changing task type" do
        it "change task type behavior" do
          step "submit button starts out disabled" do
            visit("queue/appeals/#{appeal.uuid}")
            within("tr", text: "TASK", match: :first) do
              click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                             text: COPY::CHANGE_TASK_TYPE_SUBHEAD,
                             match: :first)
            end
            modal = find(".cf-modal-body")
            expect(modal).to have_button("Change task type", disabled: true)
          end

          step "current tasks should have new task" do
            click_dropdown(prompt: "Select an action type", text: "Change of address")
            fill_in("Provide instructions and context for this change:", with: "instructions")
            click_button("Change task type")
            new_task = appeal.tasks.last
            most_recent_task = find("tr", text: "TASK", match: :first)
            expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
            expect(most_recent_task).to have_content("TASK\nChange of address")
          end

          step "case timeline should cancel old task" do
            first_task_item = find("#case-timeline-table tr:nth-child(2)")
            expect(first_task_item).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
            expect(first_task_item).to have_content("HearingPostponementRequestMailTask cancelled")
            expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
          end
        end
      end

      context "cancelling task" do
        it "cancel task behavior" do
          page = "queue/appeals/#{hpr_task.appeal.uuid}"

          step "submit button starts out disabled" do
            visit(page)
            within("tr", text: "TASK", match: :first) do
              click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                             text: Constants.TASK_ACTIONS.CANCEL_TASK.label,
                             match: :first)
            end
            modal = find(".cf-modal-body")
            expect(modal).to have_button("Submit", disabled: true)
          end

          step "should remove HearingPostponementRequestTask from current tasks" do
            fill_in("taskInstructions", with: "instructions")
            click_button("Submit")
            visit(page)
            most_recent_task = find("tr", text: "TASK", match: :first)
            expect(most_recent_task).to have_content("TASK\nAll hearing-related tasks")
          end

          step "case timeline should cancel task" do
            first_task_item = find("#case-timeline-table tr:nth-child(2)")
            expect(first_task_item).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
            expect(first_task_item).to have_content("HearingPostponementRequestMailTask cancelled")
            expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
          end
        end
      end
    end

    context "mark as complete" do
      let(:ruling_date) { "08/15/2023" }

      shared_examples "whether granted or denied" do
        it "shows correct the correct Case Timeline" do
          step "completes HearingPostponementRequestMailTask on Case Timeline" do
            mail_task = find("#case-timeline-table tr:nth-child(2)")
            expect(mail_task).to have_content("COMPLETED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
            expect(mail_task).to have_content("HearingPostponementRequestMailTask completed")
          end

          step "updates instructions of HearingPostponementRequestMailTask on Case Timeline" do
            find(:css, "#case-timeline-table .cf-btn-link", text: "View task instructions", match: :first).click
            instructions_div = find("div", class: "task-instructions")
            expect(instructions_div).to have_content("Motion to postpone #{ruling.upcase}")
            expect(instructions_div).to have_content("DATE OF RULING\n#{ruling_date}")
            expect(instructions_div).to have_content("DETAILS\n#{instructions}")
          end
        end
      end

      shared_examples "postponement granted" do
        it "previous hearing disposition is postponed" do
          visit "queue/appeals/#{appeal.uuid}"
          within(:css, "#hearing-details") do
            hearing = find(:css, ".cf-bare-list ul:nth-child(2)")
            expect(hearing).to have_content("Disposition: Postponed")
          end
        end
      end

      context "ruling is granted" do
        let(:ruling) { "Granted" }
        context "schedule immediately" do
          let!(:virtual_hearing_day) do
            create(
              :hearing_day,
              request_type: HearingDay::REQUEST_TYPES[:virtual],
              scheduled_for: Time.zone.today + 160.days,
              regional_office: "RO39"
            )
          end

          before do
            HearingsManagement.singleton.add_user(User.current_user)
            User.current_user.update!(roles: ["Build HearSched"])
            appeal.update!(closest_regional_office: "RO39")
          end

          context "AMA appeal" do
            context "unscheduled hearing" do
              include_examples "scheduling a hearing"
              include_examples "whether granted or denied"
            end

            context "scheduled hearing" do
              let(:appeal) { scheduled_appeal }
              include_examples "scheduling a hearing"
              include_examples "whether granted or denied"
            end
          end

          context "Legacy appeal" do
            let(:appeal) { legacy_appeal }
            context "unscheduled hearing" do
              include_examples "scheduling a hearing"
              include_examples "whether granted or denied"
            end

            context "scheduled hearing" do
              let(:appeal) { scheduled_legacy_appeal }
              include_examples "scheduling a hearing"
              include_examples "whether granted or denied"
            end
          end
        end

        context "send to schedule veteran list" do
          before :each do
            FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
            page = "queue/appeals/#{appeal.uuid}"
            visit(page)
            within("tr", text: "TASK", match: :first) do
              click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                             text: Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.label,
                             match: :first)
            end
            find(".cf-form-radio-option", text: ruling).click
            fill_in("rulingDateSelector", with: ruling_date)
            find(:css, ".cf-form-radio-option label", text: "Send to Schedule Veteran list").click
            fill_in("instructionsField", with: instructions)
            click_button("Mark as complete")
          end

          shared_examples "whether hearing is scheduled or unscheduled" do
            it "creates new Schedule task and cancels Hearing Task" do
              step "creates new ScheduleHearing task under Task Actions" do
                appeal
                new_task = appeal.tasks.last
                most_recent_task = find("tr", text: "TASK", match: :first)
                expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
                expect(most_recent_task).to have_content("TASK\nSchedule hearing")
              end

              step "cancels Hearing task on Case Timeline" do
                hearing_task = find("#case-timeline-table tr:nth-child(3)")

                expect(hearing_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
                expect(hearing_task).to have_content("HearingTask cancelled")
                expect(hearing_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
              end
            end
          end

          context "appeal has unscheduled hearing" do
            include_examples "whether granted or denied"
            include_examples "whether hearing is scheduled or unscheduled"

            it "cancels ScheduleHearing task on Case Timeline" do
              schedule_task = find("#case-timeline-table tr:nth-child(4)")

              expect(schedule_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
              expect(schedule_task).to have_content("ScheduleHearingTask cancelled")
              expect(schedule_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
            end
          end

          context "appeal has scheduled hearing" do
            let(:hpr_task) do
              create(:hearing_postponement_request_mail_task,
                     :postponement_request_with_scheduled_hearing,
                     assigned_by_id: User.system_user.id)
            end

            include_examples "whether granted or denied"
            include_examples "whether hearing is scheduled or unscheduled"
            include_examples "postponement granted"

            it "cancels AssignHearingDisposition task on Case Timeline" do
              disposition_task = find("#case-timeline-table tr:nth-child(4)")

              expect(disposition_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
              expect(disposition_task).to have_content("AssignHearingDispositionTask cancelled")
              expect(disposition_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
            end
          end
        end
      end

      context "ruling is denied" do
        let(:ruling) { "Denied" }
        before do
          FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
          page = "queue/appeals/#{appeal.uuid}"
          visit(page)
          click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                         text: Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.label)
          find(".cf-form-radio-option", text: ruling).click
          fill_in("rulingDateSelector", with: ruling_date)
          fill_in("instructionsField", with: instructions)
          click_button("Mark as complete")
        end
        include_examples "whether granted or denied"
      end

      describe "Hearing Withdrawal Request Mail Task" do
        before do
          HearingAdmin.singleton.add_user(User.current_user)
        end

        let(:appeal) { hwr_task.appeal }
        let(:hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_unscheduled_hearing, assigned_by_id: User.system_user.id)
        end
        let(:scheduled_hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_scheduled_hearing,
                 assigned_by_id: User.system_user.id)
        end
        let(:scheduled_appeal) { scheduled_hwr_task.appeal }
        let(:legacy_hwr_appeal) do
          create(:legacy_appeal, :with_veteran, vacols_case: create(:case))
        end
        let!(:legacy_hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_unscheduled_hearing,
                 assigned_by_id: User.system_user.id, appeal: legacy_hwr_appeal)
        end
        let(:scheduled_legacy_hwr_appeal) do
          create(:legacy_appeal, :with_veteran, vacols_case: create(:case))
        end
        let!(:scheduled_legacy_hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_scheduled_hearing,
                 assigned_by_id: User.system_user.id, appeal: scheduled_legacy_hwr_appeal)
        end
        let(:email) { "test@caseflow.com" }

        context "task actions" do
          include_examples "task reassignments"
          context "changing task type" do
            it "changing task type behavior" do
              step "submit button starts out disabled" do
                visit("queue/appeals/#{appeal.uuid}")
                within("tr", text: "TASK", match: :first) do
                  click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                                 text: COPY::CHANGE_TASK_TYPE_SUBHEAD,
                                 match: :first)
                end
                modal = find(".cf-modal-body")
                expect(modal).to have_button("Change task type", disabled: true)
              end

              step "current tasks should have new task" do
                click_dropdown(prompt: "Select an action type", text: "Change of address")
                fill_in("Provide instructions and context for this change:", with: "instructions")
                click_button("Change task type")
                new_task = appeal.tasks.last
                most_recent_task = find("tr", text: "TASK", match: :first)
                expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
                expect(most_recent_task).to have_content("TASK\nChange of address")
              end

              step "case timeline should cancel old task" do
                first_task_item = find("#case-timeline-table tr:nth-child(2)")
                expect(first_task_item).to have_content("CANCELLED ON\n#{hwr_task.updated_at.strftime('%m/%d/%Y')}")
                expect(first_task_item).to have_content("HearingWithdrawalRequestMailTask cancelled")
                expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
              end
            end
          end

          context "cancelling task" do
            it "cancel task behavior" do
              page = "queue/appeals/#{appeal.uuid}"

              step "submit button starts out disabled" do
                visit(page)
                within("tr", text: "TASK", match: :first) do
                  click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                                 text: Constants.TASK_ACTIONS.CANCEL_TASK.label,
                                 match: :first)
                end
                modal = find(".cf-modal-body")
                expect(modal).to have_button("Submit", disabled: true)
              end

              step "should remove HearingWithdrawalRequestTask from current tasks" do
                fill_in("taskInstructions", with: "instructions")
                click_button("Submit")
                visit(page)
                most_recent_task = find("tr", text: "TASK", match: :first)
                expect(most_recent_task).to have_content("TASK\nAll hearing-related tasks")
              end

              step "case timeline should cancel task" do
                first_task_item = find("#case-timeline-table tr:nth-child(2)")
                expect(first_task_item).to have_content("CANCELLED ON\n#{hwr_task.updated_at.strftime('%m/%d/%Y')}")
                expect(first_task_item).to have_content("HearingWithdrawalRequestMailTask cancelled")
                expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
              end
            end
          end
        end
      end
    end
  end

  describe "Hearing Withdrawal Request Mail Task" do
    before { HearingAdmin.singleton.add_user(User.current_user) }

    describe "mark as complete" do
      let(:date_completed) { hwr_task.updated_at.strftime("%m/%d/%Y") }

      shared_examples "modal body text" do
        it "renders proper modal body text specific to appeal type" do
          visit("queue/appeals/#{appeal.external_id}")
          within("tr", text: "Hearing withdrawal request", match: :first) do
            click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                           text: Constants.TASK_ACTIONS.COMPLETE_AND_WITHDRAW.label)
          end
          modal = find(".cf-modal-body")
          expect(modal).to have_content(modal_body_text)
        end
      end

      shared_examples "whether hearing is schedueld or unscheduled" do
        before do
          page = "queue/appeals/#{appeal.external_id}"
          visit(page)
          within("tr", text: "Hearing withdrawal request", match: :first) do
            click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                           text: Constants.TASK_ACTIONS.COMPLETE_AND_WITHDRAW.label)
          end
          fill_in("instructionsField", with: instructions)
          click_button("Mark as complete & withdraw hearing")
          visit(page)
        end

        it "Completes the HearingWithdrawalRequestMailTask, updates instructions, and cancels the HearingTask" do
          step "completes HearingWithdrawalRequestMailTask on Case Timeline" do
            mail_task = find("#case-timeline-table tr:nth-child(2)")
            expect(mail_task).to have_content("COMPLETED ON\n#{date_completed}")
            expect(mail_task).to have_content("HearingWithdrawalRequestMailTask completed")
          end

          step "updates instructions of HearingWithdrawalRequestMailTask on Case Timeline" do
            find(:css, "#case-timeline-table .cf-btn-link", text: "View task instructions", match: :first).click
            instructions_div = find("div", class: "task-instructions")
            expect(instructions_div).to have_content("Mark as complete and withdraw hearing:")
            expect(instructions_div).to have_content("DETAILS\n#{instructions}")
          end

          step "cancels HearingTask on Case Timeline" do
            hearing_task = find("#case-timeline-table tr:nth-child(3)")
            expect(hearing_task).to have_content("CANCELLED ON\n#{date_completed}")
            expect(hearing_task).to have_content("HearingTask cancelled")
            expect(hearing_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
          end
        end
      end

      shared_examples "hearing scheduled" do
        include_examples "whether hearing is schedueld or unscheduled"

        it "marks hearing disposition as canclled and cancels AssignHearingDispositionTask on the Case Timeline" do
          step "marks hearing disposition as cancelled" do
            hearing = within(:css, "#hearing-details") { find(:css, ".cf-bare-list ul:nth-child(2)") }
            expect(hearing).to have_content("Disposition: Cancelled")
          end

          step "cancels AssignHearingDispositionTask on Case Timeline" do
            disposition_task = find("#case-timeline-table tr:nth-child(4)")
            expect(disposition_task).to have_content("CANCELLED ON\n#{date_completed}")
            expect(disposition_task).to have_content("AssignHearingDispositionTask cancelled")
            expect(disposition_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
          end
        end
      end

      shared_context "async actions" do
        context "async actions" do
          it "sends withdrawal of hearing notification" do
            withdrawal_payload = AppellantNotification.create_payload(appeal, "Withdrawal of hearing").to_json
            expect(SendNotificationJob).to receive(:perform_later).with(withdrawal_payload)

            perform_enqueued_jobs do
              visit("queue/appeals/#{appeal.external_id}")
              within("tr", text: "Hearing withdrawal request", match: :first) do
                click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                               text: Constants.TASK_ACTIONS.COMPLETE_AND_WITHDRAW.label)
              end
              fill_in("instructionsField", with: instructions)
              click_button("Mark as complete & withdraw hearing")
            end
          end
        end
      end

      shared_examples "hearing unscheduled" do
        include_examples "whether hearing is schedueld or unscheduled"

        it "cancels ScheduleHearingTask on Case Timeline" do
          schedule_task = find("#case-timeline-table tr:nth-child(4)")
          expect(schedule_task).to have_content("CANCELLED ON\n#{date_completed}")
          expect(schedule_task).to have_content("ScheduleHearingTask cancelled")
          expect(schedule_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
        end
      end

      context "AMA appeal" do
        let(:hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_scheduled_hearing, assigned_by_id: User.system_user.id)
        end
        let(:appeal) { hwr_task.appeal }
        let(:modal_body_text) { COPY::WITHDRAW_HEARING["AMA"]["MODAL_BODY"] }

        shared_examples "appeal is AMA" do
          it "creates EvidenceSubmissionWindowTask" do
            evidence_task = find("tr", text: "TASK", match: :first)
            expect(evidence_task).to have_content("ASSIGNED ON\n#{date_completed}")
            expect(evidence_task).to have_content("ASSIGNED TO\nMail")
            expect(evidence_task).to have_content("Evidence Submission Window Task")
          end
        end

        include_examples "modal body text"

        context "appeal has scheduled hearing" do
          context "sync actions" do
            include_examples "hearing scheduled"
            include_examples "appeal is AMA"
          end

          include_context "async actions"
        end

        context "appeal has unscheduled hearing" do
          let(:hwr_task) do
            create(:hearing_withdrawal_request_mail_task,
                   :withdrawal_request_with_unscheduled_hearing, assigned_by_id: User.system_user.id)
          end

          include_examples "hearing unscheduled"
          include_examples "appeal is AMA"
        end
      end

      context "Legacy appeal" do
        let(:appeal) do
          create(:legacy_appeal, :with_veteran, vacols_case: create(:case))
        end
        let!(:hwr_task) do
          create(:hearing_withdrawal_request_mail_task,
                 :withdrawal_request_with_scheduled_hearing,
                 assigned_by_id: User.system_user.id, appeal: appeal)
        end
        let(:modal_body_text) do
          "The appeal will be sent to Location 81 (Case Storage) " \
          "to await distribution to a judge because the representative is a private attorney."
        end

        include_examples "modal body text"

        context "appeal has scheduled hearing" do
          context "sync actions" do
            include_examples "hearing scheduled"
          end

          include_context "async actions"
        end

        context "appeal has unscheduled hearing" do
          let(:hwr_task) do
            create(:hearing_withdrawal_request_mail_task,
                   :withdrawal_request_with_unscheduled_hearing,
                   assigned_by_id: User.system_user.id, appeal: appeal)
          end

          include_examples "hearing unscheduled"
        end
      end
    end
  end
end
