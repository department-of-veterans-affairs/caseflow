# frozen_string_literal: true

describe "Withdrawing an appeal", :postgres do
  context "appeal has one request issue and it is withdrawn" do
    it "allows it to be distributed" do
      add_blocking_mail_task_to_appeal
      withdraw_all_request_issues
      tasks = appeal.tasks.reload

      expect(all_blocking_mail_tasks(tasks).pluck(:status).uniq).to eq ["cancelled"]

      expect(distribution_task(tasks).status).to eq "assigned"
      expect(track_veteran_task(tasks).status).to eq "in_progress"
      expect(appeal.root_task.status).to eq "on_hold"
    end
  end

  context "appeal has multiple open request issues and only one is withdrawn" do
    it "does not mark it for distribution, and does not cancel active tasks" do
      withdraw_only_one_request_issue

      tasks = appeal_with_many_request_issues.tasks.reload

      expect(distribution_task(tasks).status).to eq "assigned"
      expect(track_veteran_task(tasks).status).to eq "in_progress"
      expect(appeal_with_many_request_issues.root_task.status).to eq "on_hold"
    end
  end

  context "all eligible request issues are withdrawn, and remaining ones are ineligible" do
    it "allows it to be distributed" do
      withdraw_all_eligible_request_issues

      appeal = appeal_with_ineligible_request_issues
      tasks = appeal.tasks.reload

      expect(distribution_task(tasks).status).to eq "assigned"
      expect(track_veteran_task(tasks).status).to eq "in_progress"
      expect(appeal.root_task.status).to eq "on_hold"
    end
  end

  context "appeal has withdrawn request issues and the remaining are all closed" do
    it "allows it to be distributed" do
      withdraw_request_issue_and_leave_other_one_closed

      appeal = appeal_with_closed_request_issues
      tasks = appeal.tasks.reload

      expect(distribution_task(tasks).status).to eq "assigned"
      expect(track_veteran_task(tasks).status).to eq "in_progress"
      expect(appeal.root_task.status).to eq "on_hold"
    end
  end

  context "appeal only has ineligible request issues after removing other ones" do
    it "cancels all active tasks" do
      remove_all_eligible_request_issues

      appeal = appeal_with_ineligible_request_issues
      tasks = appeal.tasks.reload

      expect(tasks.pluck(:status).uniq).to eq ["cancelled"]
    end
  end

  def add_blocking_mail_task_to_appeal
    MailTeam.singleton.add_user(user)
    CongressionalInterestMailTask.create_from_params(
      {
        appeal: appeal,
        parent_id: appeal.root_task.id
      }, user
    )
  end

  def withdraw_all_request_issues
    request_issues_data = [
      { request_issue_id: appeal.request_issues.last.id, withdrawal_date: Time.zone.now }
    ]

    RequestIssuesUpdate.new(
      user: user,
      review: appeal,
      request_issues_data: request_issues_data
    ).perform!
  end

  def withdraw_only_one_request_issue
    request_issues_data = [
      { request_issue_id: appeal_with_many_request_issues.request_issues.last.id, withdrawal_date: Time.zone.now },
      { request_issue_id: appeal_with_many_request_issues.request_issues.first.id }
    ]

    RequestIssuesUpdate.new(
      user: user,
      review: appeal_with_many_request_issues,
      request_issues_data: request_issues_data
    ).perform!
  end

  def withdraw_all_eligible_request_issues
    appeal = appeal_with_ineligible_request_issues
    ineligible_request_issue = appeal.request_issues.where.not(ineligible_reason: nil).first
    eligible_request_issue = appeal.request_issues.where(ineligible_reason: nil).first
    request_issues_data = [
      { request_issue_id: ineligible_request_issue.id },
      { request_issue_id: eligible_request_issue.id, withdrawal_date: Time.zone.now }
    ]

    RequestIssuesUpdate.new(
      user: user,
      review: appeal,
      request_issues_data: request_issues_data
    ).perform!
  end

  def remove_all_eligible_request_issues
    appeal = appeal_with_ineligible_request_issues
    ineligible_request_issue = appeal.request_issues.where.not(ineligible_reason: nil).first
    request_issues_data = [
      { request_issue_id: ineligible_request_issue.id }
    ]

    RequestIssuesUpdate.new(
      user: user,
      review: appeal,
      request_issues_data: request_issues_data
    ).perform!
  end

  def withdraw_request_issue_and_leave_other_one_closed
    appeal = appeal_with_closed_request_issues
    eligible_request_issue = appeal.request_issues.where(closed_at: nil).first
    request_issues_data = [
      { request_issue_id: eligible_request_issue.id, withdrawal_date: Time.zone.now }
    ]

    RequestIssuesUpdate.new(
      user: user,
      review: appeal,
      request_issues_data: request_issues_data
    ).perform!
  end

  def distribution_task(tasks)
    tasks.find_by(type: "DistributionTask")
  end

  def track_veteran_task(tasks)
    tasks.find_by(type: "TrackVeteranTask")
  end

  def all_blocking_mail_tasks(tasks)
    tasks.of_type(:CongressionalInterestMailTask)
  end

  def appeal
    @appeal ||= begin
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.direct_review,
        request_issues: build_list(:request_issue, 1, contested_issue_description: "Knee pain")
      )
      create_track_veteran_tasks(appeal)
      appeal
    end
  end

  def appeal_with_many_request_issues
    @appeal_with_many_request_issues ||= begin
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.direct_review
      )
      appeal.request_issues = build_list(
        :request_issue, 2, contested_issue_description: "Knee pain", decision_review: appeal
      )
      appeal.save!
      create_track_veteran_tasks(appeal)
      appeal
    end
  end

  def appeal_with_ineligible_request_issues
    @appeal_with_ineligible_request_issues ||= begin
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.direct_review
      )
      create(
        :request_issue,
        contested_issue_description: "Knee pain",
        decision_review: appeal
      )
      create(
        :request_issue,
        contested_issue_description: "Back pain",
        ineligible_reason: "untimely",
        decision_review: appeal
      )
      create_track_veteran_tasks(appeal)
      appeal
    end
  end

  def appeal_with_closed_request_issues
    @appeal_with_closed_request_issues ||= begin
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.direct_review
      )
      create(
        :request_issue,
        contested_issue_description: "Knee pain",
        decision_review: appeal
      )
      create(
        :request_issue,
        contested_issue_description: "Back pain",
        closed_status: :decided,
        closed_at: Time.zone.now,
        decision_review: appeal
      )
      create_track_veteran_tasks(appeal)
      appeal
    end
  end

  def create_track_veteran_tasks(appeal)
    create(:track_veteran_task, appeal: appeal)
  end

  def user
    @user ||= create(:user)
  end
end
