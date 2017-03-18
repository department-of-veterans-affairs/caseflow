require "rails_helper"

RSpec.feature "Admin" do
  let(:full_grant_vacols_record) { Fakes::AppealRepository.appeal_full_grant_decided }
  let(:vacols_record) { Fakes::AppealRepository.appeal_partial_grant_decided }

  let!(:current_user) { User.authenticate!(roles: ["System Admin"]) }

  let(:existing_task_vacols_record) { Fakes::AppealRepository.appeal_partial_grant_decided }
  let!(:appeal_with_existing_task) { Generators::Appeal.create(vacols_record: vacols_record) }
  let!(:existing_task) { EstablishClaim.create(appeal: appeal_with_existing_task, aasm_state: :unassigned) }

  let!(:appeal_missing_decision) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: [])
  end

  let!(:appeal) do
    Generators::Appeal.create(
      vacols_record: full_grant_vacols_record,
      documents: [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)]
    )
  end

  scenario "Establish Claim page" do
    visit "/admin/establish_claim"

    # View existing tasks
    expect(Task.count).to eq(1)
    expect(page).to have_css("#task-#{existing_task.id}")

    # Attempt to create a task without clicking on a decision
    page.fill_in "VBMS ID", with: appeal.vbms_id
    page.click_on "Create Task"
    expect(page).to have_content "You must select a decision type"

    # Attempt to create a task for an appeal that exists
    page.fill_in "VBMS ID", with: appeal_with_existing_task.vbms_id
    within_fieldset("Decision Type") do
      find("label", text: "Partial Grant or Remand").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "A task already exists for this appeal"

    # Attempt to create a task with no decision
    page.fill_in "VBMS ID", with: appeal_missing_decision.vbms_id
    within_fieldset("Decision Type") do
      find("label", text: "Partial Grant or Remand").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "This appeal did not have a decision document in VBMS"

    # Attempt to create a task for a file number with multiple appeals
    page.fill_in "VBMS ID", with: "raise_multiple_appeals_error"
    within_fieldset("Decision Type") do
      find("label", text: "Partial Grant or Remand").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "There were multiple appeals matching this VBMS ID"

    # Attempt to create a task for a file number that doesn't exist
    page.fill_in "VBMS ID", with: "not found waaaah"
    within_fieldset("Decision Type") do
      find("label", text: "Full Grant").click
    end
    page.click_on "Create Task"
    expect(page).to have_content "Appeal not found for that decision type."

    # Create a new task
    page.fill_in "VBMS ID", with: appeal.vbms_id
    within_fieldset("Decision Type") do
      find("label", text: "Full Grant").click
    end
    page.click_on "Create Task"

    # # ensure new task is created
    expect(page).to have_current_path("/admin/establish_claim")
    expect(page).to have_content "Task created"
    expect(Task.count).to eq(3)

    # # ensure that the task is unassigned
    expect(Task.to_complete.count).to eq(2)
  end
end
