# frozen_string_literal: true

feature "correcting issues", :postgres do
  include IntakeHelpers

  context "deleting a request issue that has one decision issue" do
    it "deletes the decision issue" do
      appeal = appeal_with_one_decision_issue
      create_judge_decision_review_task_for(appeal)
      first_request_issue = RequestIssue.find_by(contested_issue_description: "first description")

      visit_appeals_page_as_judge(appeal)
      remove_request_issue_as_a_judge(first_request_issue.description)

      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "first request issue"
      expect(DecisionIssue.count).to eq 1
      expect(RequestDecisionIssue.count).to eq 1
      expect(first_request_issue.reload.decision_review).to_not be_nil
      expect(first_request_issue).to be_closed
      expect(first_request_issue).to be_removed
    end
  end

  context "deleting a request issue that has multiple decision issues" do
    it "deletes all decision issues" do
      appeal = appeal_with_multiple_decision_issues
      create_judge_decision_review_task_for(appeal)
      request_issue = RequestIssue.find_by(contested_issue_description: "Many decision issues")

      visit_appeals_page_as_judge(appeal)

      remove_request_issue_as_a_judge(request_issue.description)

      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "with many decision issues"
      expect(DecisionIssue.pluck(:id)).to eq [3]
      expect(RequestDecisionIssue.count).to eq 1
      expect(request_issue.reload.decision_review).to_not be_nil
      expect(request_issue).to be_closed
      expect(request_issue).to be_removed
    end
  end

  context "deleting a request issue that has a decision issue shared with another request issue" do
    it "deletes the request issue but not the shared decision issue" do
      appeal = appeal_with_shared_decision_issues
      create_judge_decision_review_task_for(appeal)
      visit_appeals_page_as_judge(appeal)
      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
      find("label", text: "No Special Issues").click
      click_on "Continue"
      expect(page).to have_content "Added to 2 issues"
      expect(page).to have_content "decision with id 1"
      expect(page).to have_content "decision with id 2"
      page.go_back
      request_issue = RequestIssue.find_by(contested_issue_description: "shared decision issues")
      remove_request_issue_as_a_judge(request_issue.description)
      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "with a shared decision issue"
      expect(DecisionIssue.pluck(:id)).to eq [1]
      expect(RequestDecisionIssue.count).to eq 1
      expect(request_issue.reload.decision_review).to_not be_nil
      expect(request_issue).to be_closed
      expect(request_issue).to be_removed

      expect(page).to_not have_content "Added to 2 issues"
      expect(page).to_not have_content "decision with id 2"
      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
      if !find("#no_special_issues", visible: false).checked?
        find("label", text: "No Special Issues").click
      end
      click_on "Continue"
      expect(page).to have_content "decision with id 1"
      expect(page).to have_content "another shared decision issue"
    end
  end

  def create_judge_decision_review_task_for(appeal)
    root_task = create(:root_task, appeal: appeal)
    create(
      :ama_judge_decision_review_task,
      :in_progress,
      assigned_to: judge_user,
      assigned_by: attorney_user,
      appeal: appeal,
      parent: root_task
    )
  end

  def appeal_with_one_decision_issue
    appeal = create(
      :appeal,
      intake: create(:intake),
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "first request issue",
                             contested_issue_description: "first description",
                             decision_issues: [decision_issue(1)]),
        create_request_issue(notes: "second request issue",
                             contested_issue_description: "second description",
                             decision_issues: [decision_issue(2)])
      ]
    )
    DecisionIssue.find_each { |issue| issue.update(decision_review_id: Appeal.last.id) }
    appeal
  end

  def appeal_with_multiple_decision_issues
    multiple_decision_issues = [decision_issue(1), decision_issue(2)]
    appeal = create(
      :appeal,
      intake: create(:intake),
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "with many decision issues",
                             contested_issue_description: "Many decision issues",
                             decision_issues: multiple_decision_issues),
        create_request_issue(notes: "with one decision issue",
                             contested_issue_description: "One decision issue",
                             decision_issues: [decision_issue(3)])
      ]
    )
    DecisionIssue.find_each { |issue| issue.update(decision_review_id: Appeal.last.id) }
    appeal
  end

  def appeal_with_shared_decision_issues
    shared_issue = decision_issue(1)
    unique_issue = decision_issue(2)
    appeal = create(
      :appeal,
      intake: create(:intake),
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "with a shared decision issue",
                             contested_issue_description: "shared decision issues",
                             decision_issues: [shared_issue, unique_issue]),
        create_request_issue(notes: "another shared decision issue",
                             contested_issue_description: "another shared decision",
                             decision_issues: [shared_issue])
      ]
    )
    DecisionIssue.find_each { |issue| issue.update(decision_review_id: Appeal.last.id) }
    appeal
  end

  def create_request_issue(notes: nil, contested_issue_description: nil, decision_issues:)
    create(
      :request_issue,
      :rating,
      notes: notes,
      contested_issue_description: contested_issue_description,
      decision_issues: decision_issues
    )
  end

  def decision_issue(id)
    create(:decision_issue, id: id, description: "decision with id #{id}", decision_review: create(:appeal))
  end

  def judge_user
    @judge_user ||= create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge")
  end

  def attorney_user
    create(:default_user)
  end

  def visit_appeals_page_as_judge(appeal)
    User.authenticate!(user: judge_user)
    visit "/queue"
    click_link "(#{appeal.veteran_file_number})"
  end

  def remove_request_issue_as_a_judge(description)
    click_link "Correct issues"
    click_remove_intake_issue_dropdown(description)
    click_edit_submit_and_confirm
  end
end
