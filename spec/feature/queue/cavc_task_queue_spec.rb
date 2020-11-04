# frozen_string_literal: true

RSpec.feature "CAVC-related tasks queue", :all_dbs do
  let!(:org_admin) do
    create(:user, full_name: "Adminy CacvRemandy") do |u|
      CavcLitigationSupport.singleton.add_user(u)
      OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
    end
  end
  let!(:org_nonadmin) { create(:user, full_name: "Woney Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:org_nonadmin2) { create(:user, full_name: "Tooey Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:other_user) { create(:user, full_name: "Othery Usery") }

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
      expect(page).to have_content Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.label
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

      find(".cf-select__control", text: "Select an action").click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click
      fill_in "completeTaskInstructions", with: "Letter sent."
      click_on COPY::MARK_TASK_COMPLETE_BUTTON
      expect(page).to have_content COPY::MARK_TASK_COMPLETE_CONFIRMATION % send_task.appeal.veteran_full_name
    end
  end
end
