# frozen_string_literal: true

RSpec.feature "MailTasks", :postgres do
  let(:user) { create(:user) }

  before do
    User.authenticate!(user: user)
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

  describe "Hearing Postponement Request Mail Task" do
    before do
      HearingAdmin.singleton.add_user(User.current_user)
    end
    let(:hpr_task) { create(:hearing_postponement_request_mail_task, :with_unscheduled_hearing, assigned_by_id: User.system_user.id) }
    let(:appeal) { hpr_task.appeal }

    context "changing task type" do
      it "submit button starts out disabled" do
        visit("queue/appeals/#{hpr_task.appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: COPY::CHANGE_TASK_TYPE_SUBHEAD)
        modal = find(".cf-modal-body")
        expect(modal).to have_button("Change task type", disabled: true)
      end

      it "current tasks should have new task" do
        appeal = hpr_task.appeal
        visit("queue/appeals/#{appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: COPY::CHANGE_TASK_TYPE_SUBHEAD)
        find(".cf-select__control", text: "Select an action type").click
        find(".cf-select__option", text: "Change of address").click
        fill_in("Provide instructions and context for this change:", with: "instructions")
        click_button("Change task type")
        new_task = appeal.tasks.last
        most_recent_task = find("tr", text: "TASK", match: :first)
        expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
        expect(most_recent_task).to have_content("TASK\nChange of address")
      end

      it "case timeline should cancel old task" do
        visit("queue/appeals/#{hpr_task.appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: COPY::CHANGE_TASK_TYPE_SUBHEAD)
        find(".cf-select__control", text: "Select an action type").click
        find(".cf-select__option", text: "Change of address").click
        fill_in("Provide instructions and context for this change:", with: "instructions")
        click_button("Change task type")
        first_task_item = find("#case-timeline-table tr:nth-child(2)")
        expect(first_task_item).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
        expect(first_task_item).to have_content("HearingPostponementRequestMailTask cancelled")
        expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
      end
    end

    context "assigning to new team" do
      it "submit button starts out disabled" do
        visit("queue/appeals/#{hpr_task.appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.label)
        modal = find(".cf-modal-body")
        expect(modal).to have_button("Submit", disabled: true)
      end

      it "assigns to new team" do
        appeal = hpr_task.appeal
        page = "queue/appeals/#{appeal.uuid}"
        visit(page)
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.label)
        find(".cf-select__control", text: "Select a team").click
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

    context "assigning to person" do
      it "submit button starts out disabled" do
        visit("queue/appeals/#{hpr_task.appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                       text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label)
        modal = find(".cf-modal-body")
        expect(modal).to have_button("Submit", disabled: true)
      end

      it "assigns to person" do
        new_user = User.create!(css_id: "NEW_USER", full_name: "John Smith", station_id: "101")
        HearingAdmin.singleton.add_user(new_user)
        appeal = hpr_task.appeal
        page = "queue/appeals/#{appeal.uuid}"
        visit(page)
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                       text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label)
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

    context "cancelling task" do
      it "submit button starts out disabled" do
        visit("queue/appeals/#{hpr_task.appeal.uuid}")
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.CANCEL_TASK.label)
        modal = find(".cf-modal-body")
        expect(modal).to have_button("Submit", disabled: true)
      end

      it "should remove HearingPostponementRequestTask from current tasks" do
        page = "queue/appeals/#{hpr_task.appeal.uuid}"
        visit(page)
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.CANCEL_TASK.label)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")
        visit(page)
        most_recent_task = find("tr", text: "TASK", match: :first)
        expect(most_recent_task).to have_content("TASK\nAll hearing-related tasks")
      end

      it "case timeline should cancel task" do
        page = "queue/appeals/#{hpr_task.appeal.uuid}"
        visit(page)
        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.CANCEL_TASK.label)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")
        visit(page)
        first_task_item = find("#case-timeline-table tr:nth-child(2)")
        expect(first_task_item).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
        expect(first_task_item).to have_content("HearingPostponementRequestMailTask cancelled")
        expect(first_task_item).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
      end
    end

    context "mark as complete" do
      let(:ruling_date) { "08/15/2023" }
      let(:instructions) { "instructions" }

      shared_examples "whether granted or denied" do
        it "completes HearingPostponementRequestMailTask on Case Timeline" do
          hpr_task = find("#case-timeline-table tr:nth-child(1)")

          expect(hpr_task).to have_content("COMPLETED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
          expect(hpr_task).to have_content("HearingPostponementRequestMailTask completed")
          expect(hpr_task).to have_content("COMPLETED BY\n#{User.current_user.css_id}")
        end

        it "updates instructions of HearingPostponementRequestMailTask on Case Timeline" do
          find(:css, "#case-timeline-table .cf-btn-link", text: "View task instructions", match: :first).click
          instructions = find("div", class: ".task-instructions")

          expect(instructions).to have_content("Motion to postpone #{ruling}")
          expect(instructions).to have_content("DATE OF RULING\n#{ruling_date}")
          expect(instructions).to have_content("INSTRUCTIONS\n#{instructions}")
        end
      end

      context "ruling is granted" do
        let(:ruling) { "GRANTED"}

        context "scheduling a veteran immediately" do
          # it "schedule a veteran" do
          #   FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
          #   p = "queue/appeals/#{hpr_task.appeal.uuid}"
          #   visit(p)
          #   click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          #                  text: "Mark as complete")
          #   find(".cf-form-radio-option", text: "Granted").click
          #   fill_in("rulingDateSelector", with: "08/15/2023")
          #   find(:css, ".cf-form-radio-option label", text: "Reschedule immediately").click
          #   fill_in("instructionsField", with: "instructions")
          #   click_button("Mark as complete")
          #   expect(page.current_path).to eq("/queue/appeals/#{hpr_task.appeal.uuid}/tasks/#{hpr_task.id}/modal/complete_and_postpone")
          # end
        end

        context "send to schedule veteran list" do
          before :each do
            FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
            page = "queue/appeals/#{appeal.uuid}"
            visit(page)
            click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                           text: Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.label)
            find(".cf-form-radio-option", text: "Granted").click
            fill_in("rulingDateSelector", with: ruling_date)
            find(:css, ".cf-form-radio-option label", text: "Send to Schedule Veteran list").click
            fill_in("instructionsField", with: instructions)
            click_button("Mark as complete")
          end

          shared_examples "whether or not appeal has scheduled hearing" do
            it "creates new ScheduleHearing task under Task Actions" do
              new_task = appeal.tasks.last
              most_recent_task = find("tr", text: "TASK", match: :first)
              expect(most_recent_task).to have_content("ASSIGNED ON\n#{new_task.assigned_at.strftime('%m/%d/%Y')}")
              expect(most_recent_task).to have_content("TASK\nSchedule hearing")
            end

            it "cancels Hearing task on Case Timeline" do
              hearing_task = find("#case-timeline-table tr:nth-child(2)")

              expect(hearing_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
              expect(hearing_task).to have_content("HearingTask cancelled")
              expect(hearing_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
            end
          end

          context "appeal has unscheduled hearing" do
            let(:hpr_task) do
              create(:hearing_postponement_request_mail_task,
                     :with_unscheduled_hearing,
                     assigned_by_id: User.system_user.id)
            end

            include_examples "whether granted or denied"
            include_examples "whether or not appeal has scheduled hearing"

            it "cancels ScheduleHearing task on Case Timeline" do
              schedule_task = find("#case-timeline-table tr:nth-child(3)")

              expect(schedule_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
              expect(schedule_task).to have_content("ScheduleHearingTask cancelled")
              expect(schedule_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
            end
          end

          context "appeal has scheduled hearing" do
            let(:hpr_task) do
              create(:hearing_postponement_request_mail_task,
                     :with_scheduled_hearing,
                     assigned_by_id: User.system_user.id)
            end

            include_examples "whether granted or denied"
            include_examples "whether or not appeal has scheduled hearing"

            it "cancels AssignHearingDisposition task on Case Timeline" do
              disposition_task = find("#case-timeline-table tr:nth-child(3)")

              expect(disposition_task).to have_content("CANCELLED ON\n#{hpr_task.updated_at.strftime('%m/%d/%Y')}")
              expect(disposition_task).to have_content("AssignHearingDispositionTask cancelled")
              expect(disposition_task).to have_content("CANCELLED BY\n#{User.current_user.css_id}")
            end
          end
        end
      end

      context "ruling is denied" do
        let(:ruling) { "DENIED" }

        before do
          FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
          page = "queue/appeals/#{appeal.uuid}"
          visit(page)
          click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
                         text: Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.label)
          find(".cf-form-radio-option", text: "Denied").click
          fill_in("rulingDateSelector", with: ruling_date)
          fill_in("instructionsField", with: instructions)
          click_button("Mark as complete")
        end

        include_examples "whether granted or denied"
      end
    end
  end
end
