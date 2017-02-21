require "rails_helper"

RSpec.feature "Admin" do
  before do
    User.authenticate!(roles: ["System Admin"])
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_full_grant_decided
    }
    @vbms_id = "7777"

    appeal = Appeal.create(
      vacols_id: "123C",
      vbms_id: @vbms_id
    )
    @task = EstablishClaim.create(appeal: appeal)
  end

  scenario "Establish Claim page" do
    visit "/admin/establish_claim"

    # view existing tasks
    expect(Task.count).to eq(1)
    expect(Task.to_complete.count).to eq(0)
    expect(page).to have_css("#task-#{@task.id}")

    # attempt to create a task without clicking on a decision
    page.fill_in "VBMS ID", with: "FULLGRANT_VBMS_ID"
    page.click_on "Create Task"
    expect(page).to have_content "You must select a decision type"

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
    expect(Task.count).to eq(2)

    # ensure that the task is unassigned
    expect(Task.to_complete.count).to eq(1)
  end
end
