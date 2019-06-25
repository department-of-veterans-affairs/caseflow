# frozen_string_literal: true

class AppealRequestIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def editable?
    return true if case_review_team_member?

    appeal_has_in_progress_or_assigned_judge_or_attorney_tasks_assigned_to_user?
  end

  private

  attr_reader :user, :appeal

  def case_review_team_member?
    BvaIntake.singleton.user_has_access?(user)
  end

  def appeal_has_in_progress_or_assigned_judge_or_attorney_tasks_assigned_to_user?
    Task.where(
      appeal: appeal,
      assigned_to: user,
      status: [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    ).select { |task| task.is_a?(JudgeTask) || task.is_a?(AttorneyTask) }.any?
  end
end
