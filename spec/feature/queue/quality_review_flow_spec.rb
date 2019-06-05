# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Quality Review worflow" do
  let(:valid_document_id) { "12345-12345678" }

  let(:veteran_first_name) { "Marissa" }
  let(:veteran_last_name) { "Vasquez" }
  let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
  let!(:veteran) { FactoryBot.create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }

  let(:qr_user_name) { "QR User" }
  let(:qr_user_name_short) { "Q. User" }
  let!(:qr_user) { FactoryBot.create(:user, roles: ["Reader"], full_name: qr_user_name) }

  let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Javitz") }
  let!(:judge_staff) { FactoryBot.create(:staff, :judge_role, user: judge_user) }

  let(:attorney_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Nicole Apple") }
  let!(:attorney_staff) { FactoryBot.create(:staff, :attorney_role, user: attorney_user) }

  let!(:quality_review_organization) { QualityReview.singleton }
  let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }
  let!(:appeal) { FactoryBot.create(:appeal, veteran_file_number: veteran.file_number) }
  let!(:request_issue) { create(:request_issue, decision_review: appeal) }

  let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
  let!(:judge_task) do
    FactoryBot.create(:ama_judge_task, appeal: appeal, parent: root_task, assigned_to: judge_user, status: :completed)
  end
  let!(:attorney_task) do
    FactoryBot.create(:ama_attorney_task, appeal: appeal, parent: judge_task, assigned_to: attorney_user, status: :completed)
  end
  let!(:qr_task) do
    FactoryBot.create(
      :qr_task,
      :in_progress,
      assigned_to: quality_review_organization,
      assigned_by: judge_user,
      parent: root_task,
      appeal: appeal
    )
  end

  let!(:qr_instructions) { "Fix this case!" }

  before do
    ["Reba Janowiec", "Lee Jiang", "Pearl Jurs"].each do |judge_name|
      FactoryBot.create(
        :staff,
        :judge_role,
        user: FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: judge_name)
      )
    end

    OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)

    FactoryBot.create(:staff, user: qr_user)
    OrganizationsUser.add_user_to_organization(qr_user, quality_review_organization)
    User.authenticate!(user: qr_user)
  end

  scenario "return case to judge" do
    expect(QualityReviewTask.count).to eq 1

    step "QR user visits the quality review organization page and assigns the task to themself" do
      visit quality_review_organization.path
      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label]).click

      fill_in "taskInstructions", with: "Review the quality"
      click_on "Submit"

      expect(page).to have_content("Task assigned to #{qr_user_name}")

      expect(QualityReviewTask.count).to eq 2
    end

    step "QR user returns the case to a judge" do
      click_on "Caseflow"

      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.QR_RETURN_TO_JUDGE.to_h[:label]).click

      expect(dropdown_selected_value(find(".cf-modal-body"))).to eq judge_user.full_name
      fill_in "taskInstructions", with: qr_instructions

      click_on "Submit"

      expect(page).to have_content("On hold (1)")
    end

    step "judge reviews case and assigns a task to an attorney" do
      User.authenticate!(user: judge_user)

      visit "/queue"

      click_on veteran_full_name

      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click

      expect(page).to have_content(qr_instructions)

      find(".Select-control", text: "Select an action", match: :first).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.to_h[:label]).click

      expect(dropdown_selected_value(find(".cf-modal-body"))).to eq attorney_user.full_name
      click_on "Submit"

      expect(page).to have_content("Task assigned to #{attorney_user.full_name}")
    end

    step "attorney completes task and returns the case to the judge" do
      User.authenticate!(user: attorney_user)

      visit "/queue"

      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h[:label]).click

      expect(page).not_to have_content("Select special issues (optional)")

      expect(page).to have_content("Add decisions")
      all("button", text: "+ Add decision", count: 1)[0].click
      expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

      fill_in "Text Box", with: "test"
      find(".Select-control", text: "Select disposition").click
      find("div", class: "Select-option", text: "Allowed").click

      click_on "Save"

      click_on "Continue"

      expect(page).to have_content("Submit Draft Decision for Review")

      fill_in "Document ID:", with: valid_document_id
      # the judge should be pre selected
      expect(page).to have_content(judge_user.full_name)
      fill_in "notes", with: "all done"

      click_on "Continue"

      expect(page).to have_content(
        "Thank you for drafting #{veteran_full_name}'s decision. It's been sent to #{judge_user.full_name} for review."
      )
    end

    step "judge completes task" do
      User.authenticate!(user: judge_user)

      visit "/queue"

      click_on veteran_full_name

      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click
      expect(page).to have_content(qr_instructions)

      find(".Select-control", text: "Select an action", match: :first).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      expect(page).to have_content("Mark as complete")

      click_on "Mark complete"

      expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")
    end

    step "QR reviews case" do
      User.authenticate!(user: qr_user)

      visit "/queue"

      click_on veteran_full_name

      expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      expect(page).to have_content("Mark as complete")

      click_on "Mark complete"

      expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")
      # ensure no duplicate org tasks
      page.go_back

      page.find("table#case-timeline-table").assert_text("QualityReviewTask", count: 1)
    end
  end
end
