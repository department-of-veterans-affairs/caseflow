# frozen_string_literal: true

class AppealRequestIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def editable?
    editable_by_case_review_team_member? || case_is_in_active_review_by_current_user? ||
      hearing_is_assigned_to_judge_user? || editable_by_cavc_team_member?
  end

  private

  attr_reader :user, :appeal

  def editable_by_case_review_team_member?
    current_user_can_edit_issues? && case_is_not_in_active_review?
  end

  def editable_by_cavc_team_member?
    CavcLitigationSupport.singleton.users.include?(user) &&
      appeal.tasks.open.where(type: :CavcTask).any?
  end

  def current_user_can_edit_issues?
    user&.can_edit_issues?
  end

  def case_is_not_in_active_review?
    Task.where(
      appeal: appeal,
      type: "AttorneyTask",
      status: [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    ).empty?
  end

  def hearing_is_assigned_to_judge_user?
    appeal.hearings.last&.judge == user
  end

  def case_is_in_active_review_by_current_user?
    Task.where(
      appeal: appeal,
      assigned_to: user,
      status: [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    ).select { |task| task.is_a?(JudgeTask) || task.is_a?(AttorneyTask) }.any?
  end
end
