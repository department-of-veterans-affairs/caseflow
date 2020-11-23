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

  context "when CAVC Lit Support is assigned SendCavcRemandProcessedLetterTask" do
    let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }

    it "allows admin to assign SendCavcRemandProcessedLetterTask to user" do
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

      # Logged in as second user assignee (due to reassignment)
      User.authenticate!(user: org_nonadmin2)
      visit "queue/appeals/#{send_task.appeal.external_id}"

      # Assign some admin actions that does not block the sending of the 90 day letter
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

      # Assign an admin action that DOES block the sending of the 90 day letter
      click_dropdown(text: Constants.TASK_ACTIONS.CLARIFY_POA_BLOCKING_CAVC.label)
      fill_in "taskInstructions", with: "Please find out the POA for this veteran"
      click_on "Submit"
      expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % CavcLitigationSupport.singleton.name

      # Ensure there are no actions on the send letter task as it is blocked by poa clarification
      active_task_rows = page.find("#currently-active-tasks").find_all("tr")
      poa_task_row = active_task_rows[0]
      send_task_row = active_task_rows[-2]
      expect(poa_task_row).to have_content("TASK\n#{COPY::CAVC_POA_TASK_LABEL}")
      expect(poa_task_row.find(".taskActionsContainerStyling").all("*", wait: false).length).to be > 0
      expect(send_task_row).to have_content("TASK\n#{COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_LABEL}")
      expect(send_task_row.find(".taskActionsContainerStyling").all("*", wait: false).length).to be 0

      # Complete the task to unblock
      click_dropdown(text: Constants.TASK_ACTIONS.MARK_COMPLETE.label)
      fill_in "completeTaskInstructions", with: "POA verified"
      click_on COPY::MARK_TASK_COMPLETE_BUTTON
      visit "queue/appeals/#{send_task.appeal.external_id}"
      send_task_row = page.find("#currently-active-tasks").find_all("tr")[-2]
      expect(send_task_row.find(".taskActionsContainerStyling").all("*", wait: false).length).to be > 0

      find(".cf-select__control", text: "Select an action").click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click
      fill_in "completeTaskInstructions", with: "Letter sent."
      click_on COPY::MARK_TASK_COMPLETE_BUTTON
      expect(page).to have_content COPY::MARK_TASK_COMPLETE_CONFIRMATION % send_task.appeal.veteran_full_name
    end
  end
end
