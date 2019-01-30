require "rails_helper"

feature "correcting issues" do
  before { FeatureToggle.enable!(:ama_decision_issues) }
  after { FeatureToggle.disable!(:ama_decision_issues) }

  context "deleting a request issue that has one decision issue" do
    it "deletes the decision issue" do
      appeal = appeal_with_one_decision_issue
      create_judge_decision_review_task_for(appeal)
      first_request_issue = RequestIssue.find_by(notes: "first request issue")

      visit_appeals_page_as_judge(appeal)
      remove_request_issue_as_a_judge(first_request_issue)

      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "first request issue"
      expect(DecisionIssue.count).to eq 1
      expect(RequestDecisionIssue.count).to eq 1
      expect(first_request_issue.reload.review_request_id).to be_nil
      expect(first_request_issue.reload.review_request_type).to be_nil
    end
  end

  context "deleting a request issue that has multiple decision issues" do
    it "deletes all decision issues" do
      appeal = appeal_with_multiple_decision_issues
      create_judge_decision_review_task_for(appeal)
      request_issue = RequestIssue.find_by(notes: "with many decision issues")

      visit_appeals_page_as_judge(appeal)
      remove_request_issue_as_a_judge(request_issue)

      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "with many decision issues"
      expect(DecisionIssue.pluck(:id)).to eq [3]
      expect(RequestDecisionIssue.count).to eq 1
      expect(request_issue.reload.review_request_id).to be_nil
      expect(request_issue.reload.review_request_type).to be_nil
    end
  end

  context "deleting a request issue that has a decision issue shared with another request issue" do
    it "deletes the request issue but not the shared decision issue" do
      appeal = appeal_with_shared_decision_issues
      create_judge_decision_review_task_for(appeal)
      visit_appeals_page_as_judge(appeal)

      expect(page).to have_content "Added to 2 issues"
      expect(page).to have_content "decision with id 1"
      expect(page).to have_content "decision with id 2"

      request_issue = RequestIssue.find_by(notes: "with a shared decision issue")
      remove_request_issue_as_a_judge(request_issue)

      expect(page).to have_link "Correct issues"
      expect(page).to_not have_content "with a shared decision issue"
      expect(DecisionIssue.pluck(:id)).to eq [1]
      expect(RequestDecisionIssue.count).to eq 1
      expect(request_issue.reload.review_request_id).to be_nil
      expect(request_issue.reload.review_request_type).to be_nil
      expect(page).to_not have_content "Added to 2 issues"
      expect(page).to_not have_content "decision with id 2"
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
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "first request issue", decision_issues: [decision_issue(1)]),
        create_request_issue(notes: "second request issue", decision_issues: [decision_issue(2)])
      ]
    )
    DecisionIssue.find_each { |issue| issue.update(decision_review_id: Appeal.last.id) }
    appeal
  end

  def appeal_with_multiple_decision_issues
    multiple_decision_issues = [decision_issue(1), decision_issue(2)]
    appeal = create(
      :appeal,
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "with many decision issues", decision_issues: multiple_decision_issues),
        create_request_issue(notes: "with one decision issue", decision_issues: [decision_issue(3)])
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
      number_of_claimants: 1,
      request_issues: [
        create_request_issue(notes: "with a shared decision issue", decision_issues: [shared_issue, unique_issue]),
        create_request_issue(notes: "another shared decision issue", decision_issues: [shared_issue])
      ]
    )
    DecisionIssue.find_each { |issue| issue.update(decision_review_id: Appeal.last.id) }
    appeal
  end

  def create_request_issue(notes:, decision_issues:)
    create(
      :request_issue,
      notes: notes,
      decision_issues: decision_issues
    )
  end

  def decision_issue(id)
    create(:decision_issue, id: id, description: "decision with id #{id}", decision_review_type: "Appeal")
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

  def remove_request_issue_as_a_judge(request_issue)
    click_link "Correct issues"
    within("#issue-#{request_issue.id}") do
      click_button "Remove"
    end
    click_on "Yes, remove issue"
    click_on "Save"
    click_button "Yes, save"
  end
end
