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

  before { Colocated.singleton.add_user(create(:user)) }

  describe "when CAVC Lit Support is assigned SendCavcRemandProcessedLetterTask" do
    let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    let(:vet_name) { send_task.appeal.veteran_full_name }

    it "allows users to assign and process tasks" do
      step "admin assigns SendCavcRemandProcessedLetterTask to user" do
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
      end
      
      step "assigned user reassigns SendCavcRemandProcessedLetterTask" do
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

      step "assigned user adds admin actions" do
        # Logged in as second user assignee (due to reassignment)
        User.authenticate!(user: org_nonadmin2)
        visit "queue/appeals/#{send_task.appeal.external_id}"
        
        click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.label)
        fill_in "taskInstructions", with: "Please translate the documents in spanish"
        click_on "Submit"
        expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % Translation.singleton.name

        click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION.label)
        fill_in "taskInstructions", with: "Please transcribe the hearing on record for this appeal"
        click_on "Submit"
        expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % TranscriptionTeam.singleton.name

        click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_PRIVACY_TEAM_BLOCKING_DISTRIBUTION.label)
        fill_in "taskInstructions", with: "Please handle the freedom of intformation act request for this appeal"
        click_on "Submit"
        expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % PrivacyTeam.singleton.name

        click_dropdown(text: Constants.TASK_ACTIONS.SEND_IHP_TO_COLOCATED_BLOCKING_DISTRIBUTION.label)
        fill_in "taskInstructions", with: "Have veteran's POA write an informal hearing presentation for this appeal"
        click_on "Submit"
        expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % Colocated.singleton.name
      end

      step "assigned user completes task" do
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
