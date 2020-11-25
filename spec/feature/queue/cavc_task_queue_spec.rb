# frozen_string_literal: true

RSpec.feature "CAVC-related tasks queue", :all_dbs do
  let!(:org_admin) do
    create(:user, full_name: "Adminy CacvRemandy") do |u|
      OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
    end
  end
  let!(:org_nonadmin) { create(:user, full_name: "Woney Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:org_nonadmin2) { create(:user, full_name: "Tooey Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:other_user) { create(:user, full_name: "Othery Usery") }

  include IntakeHelpers
  describe "when CAVC Lit Support has a CAVC Remand case" do
    let(:cavc_task) { create(:cavc_task) }
    let!(:appeal) { cavc_task.appeal }
    let(:decision_issue) { create(:decision_issue, description: "decision 1", decision_review: appeal) }
    let!(:request_issue) do
      create(:request_issue, :rating, decision_review: appeal,
                                      contested_issue_description: "issue description",
                                      notes: "notes from NOD",
                                      decision_issues: [decision_issue])
    end

    let!(:new_issue_description) { "Some description for new issue" }

    it "allows CAVC Team users to correct issues" do
      step "check 'Correct issues' link does not appear for users not in the CAVC Team" do
        User.authenticate!(user: other_user)
        visit "queue/appeals/#{appeal.external_id}"
        expect(page).to_not have_content "Correct issues"
      end

      step "check 'Correct issues' link appears" do
        User.authenticate!(user: org_nonadmin)
        visit "queue/appeals/#{appeal.external_id}"
        expect(page).to have_content "Correct issues"
      end

      step "add an issue" do
        click_on "Correct issues"
        expect(appeal.request_issues.count).to eq 1
        click_on "+ Add issue"
        add_intake_nonrating_issue(
          category: "Unknown issue category",
          description: new_issue_description,
          date: (Time.zone.now - 100.days).mdY
        )
        click_edit_submit_and_confirm
        expect(page).to have_content "Edit Completed"
        expect(page).to have_content "You have successfully added 1 issue."
        expect(appeal.request_issues.count).to eq 2
      end

      step "remove an issue" do
        click_link "Correct issues"
        click_remove_intake_issue_dropdown(new_issue_description)
        click_edit_submit_and_confirm
        expect(page).to have_content "Edit Completed"
        expect(page).to have_content "You have successfully removed 1 issue."
        expect(appeal.request_issues.where(closed_status: nil).count).to eq 1
      end
    end
  end

  describe "when CAVC Lit Support is assigned SendCavcRemandProcessedLetterTask" do
    let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    let(:vet_name) { send_task.appeal.veteran_full_name }

    it "allows users to assign and process tasks" do
      step "allows admin to assign SendCavcRemandProcessedLetterTask to user" do
        # Logged in as CAVC Lit Support admin
        User.authenticate!(user: org_admin)
        visit "queue/appeals/#{send_task.appeal.external_id}"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label).click

        find(".cf-select__control", text: org_admin.full_name).click
        find("div", class: "cf-select__option", text: org_nonadmin.full_name).click
        fill_in "taskInstructions", with: "Confirm info and send letter to Veteran."
        click_on "Submit"
        expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % org_nonadmin.full_name

        # Logged in as first user assignee
        User.authenticate!(user: org_nonadmin)
        visit "queue/appeals/#{send_task.appeal.external_id}"

        find(".cf-select__control", text: "Select an action").click
        expect(page).to have_content Constants.TASK_ACTIONS.MARK_COMPLETE.label
        expect(page).to have_content Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label

        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label).click
        find(".cf-select__control", text: COPY::ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER).click
        find("div", class: "cf-select__option", text: org_nonadmin2.full_name).click
        fill_in "taskInstructions", with: "Going fishing. Handing off to you."
        click_on "Submit"
        expect(page).to have_content COPY::REASSIGN_TASK_SUCCESS_MESSAGE % org_nonadmin2.full_name
      end

      step "assigned user completes task" do
        # Logged in as second user assignee (due to reassignment)
        User.authenticate!(user: org_nonadmin2)
        visit "queue/appeals/#{send_task.appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.MARK_COMPLETE.label)
        fill_in "completeTaskInstructions", with: "Letter sent."
        click_on COPY::MARK_TASK_COMPLETE_BUTTON
        expect(page).to have_content COPY::MARK_TASK_COMPLETE_CONFIRMATION % vet_name

        # Check that appeal is in correct tab in user's queue
        find(".cf-tab", text: "Completed").click
        expect(page).to have_content send_task.appeal.docket_number

        # Check that appeal is in correct tab in Team view
        User.authenticate!(user: org_admin)
        visit "organizations/cavc-lit-support"
        find(".cf-tab", text: "Assigned").click
        expect(page).to have_content send_task.appeal.docket_number
        # Check that org_admin has option to End hold early
        visit "queue/appeals/#{send_task.appeal.external_id}"
        click_dropdown(text: Constants.TASK_ACTIONS.END_TIMED_HOLD.label)
        click_on "Cancel"
      end

      step "end timed hold early" do
        # Actually "End hold early" as org_nonadmin this time
        User.authenticate!(user: org_nonadmin2)
        visit "queue/appeals/#{send_task.appeal.external_id}"
        click_dropdown(text: Constants.TASK_ACTIONS.END_TIMED_HOLD.label)
        click_on "Submit"
        expect(page).to have_content COPY::END_HOLD_SUCCESS_MESSAGE_TITLE
      end

      step "resume hold" do
        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label).click
        find(".cf-select__control", text: "Select number of days").click
        find("div", class: "cf-select__option", text: "90 days").click
        fill_in "instructions", with: "Put it back on hold. Wait for more Veteran responses."
        click_on "Submit"
        expect(page).to have_content(format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, vet_name, 90))

        # Check that appeal is back in correct tab in user's queue
        visit "/queue"
        find(".cf-tab", text: "Completed").click
        expect(page).to have_content send_task.appeal.docket_number

        # Check that appeal is back in correct tab in Team view
        User.authenticate!(user: org_admin)
        visit "organizations/cavc-lit-support"
        find(".cf-tab", text: "Assigned").click
        expect(page).to have_content send_task.appeal.docket_number
      end

      step "travel 90+ days into the future to trigger TimedHoldTask to expire" do
        Timecop.travel(Time.zone.now + 90.days + 1.hour)
        TaskTimerJob.perform_now

        visit "organizations/cavc-lit-support"
        find(".cf-tab", text: "Unassigned").click
        expect(page).to have_content send_task.appeal.docket_number

        # Check case details page has action to place on hold
        visit "queue/appeals/#{send_task.appeal.external_id}"
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        click_on "Cancel"
      end
    end
  end
end
