require "rails_helper"

RSpec.feature "Admin" do
  before do
    User.authenticate!(roles: ["System Admin"])
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_partial_grant_decided,
      "456D" => Fakes::AppealRepository.appeal_full_grant_decided,
      "789E" => Fakes::AppealRepository.appeal_partial_grant_decided(vbms_id: "789E", missing_decision: true)
    }
    @vbms_id = "REMAND_VBMS_ID"

    appeal = Appeal.create(
      vacols_id: "123C",
      vbms_id: @vbms_id
    )
    @task = EstablishClaim.create(appeal: appeal)
    @task.prepare!
  end

  scenario "Establish Claim page" do
    visit "/admin/establish_claim"

    # view existing tasks
    expect(Task.count).to eq(1)
    expect(page).to have_css("#task-#{@task.id}")

    # attempt to create a task without clicking on a decision
    page.fill_in "VBMS ID", with: "FULLGRANT_VBMS_ID"
    page.click_on "Create Task"
    expect(page).to have_content "You must select a decision type"

    # attempt to create a task for an appeal that exists
    page.fill_in "VBMS ID", with: @vbms_id
    within_fieldset("Decision Type") do
      find("label", text: "Partial Grant or Remand").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "A task already exists for this appeal"

    # attempt to create a task with no decision
    page.fill_in "VBMS ID", with: "789E"
    within_fieldset("Decision Type") do
      find("label", text: "Partial Grant or Remand").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "This appeal did not have a decision document in VBMS"

    # attempt to create a task for a file number with multiple appeals
    page.fill_in "VBMS ID", with: "raise_multiple_appeals_error"
    within_fieldset("Decision Type") do
      find("label", text: "Full Grant").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "There were multiple appeals matching this VBMS ID"

    # attempt to create a task for a file number with multiple appeals
    page.fill_in "VBMS ID", with: "not found waaaah"
    within_fieldset("Decision Type") do
      find("label", text: "Full Grant").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "Appeal not found for that decision type."

    # create a new task
    page.fill_in "VBMS ID", with: "FULLGRANT_VBMS_ID"
    within_fieldset("Decision Type") do
      find("label", text: "Full Grant").click
    end
    page.click_on "Create Task"

    # ensure new task is created
    expect(page).to have_current_path("/admin/establish_claim")
    expect(page).to have_content "Task created"
    expect(Task.count).to eq(3)

    # ensure that the task is unassigned
    expect(Task.to_complete.count).to eq(2)
  end
end
