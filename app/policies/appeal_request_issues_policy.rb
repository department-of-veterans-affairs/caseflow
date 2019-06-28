# frozen_string_literal: true

class AppealRequestIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def editable?
    return true if editable_by_case_review_team_member?

    case_is_in_active_review_by_current_user?
  end

  private

  attr_reader :user, :appeal

  def editable_by_case_review_team_member?
    current_user_is_case_review_team_member? && case_is_not_in_active_review?
  end

  def current_user_is_case_review_team_member?
    BvaIntake.singleton.user_has_access?(user)
  end

  def case_is_not_in_active_review?
    Task.where(appeal: appeal, type: "AttorneyTask").empty?
  end

  def case_is_in_active_review_by_current_user?
    Task.where(
      appeal: appeal,
      assigned_to: user,
      status: [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    ).select { |task| task.is_a?(JudgeTask) || task.is_a?(AttorneyTask) }.any?
  end
end
