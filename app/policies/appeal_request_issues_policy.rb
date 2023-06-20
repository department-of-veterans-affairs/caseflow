# frozen_string_literal: true

class AppealRequestIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def editable?
    editable_by_case_review_team_member? || case_is_in_active_review_by_current_user? ||
      hearing_is_assigned_to_judge_user? || editable_by_cavc_team_member? ||
      editable_by_ssc_team_member? || editable_by_cob_team_member?
  end

  def legacy_issues_editable?
    FeatureToggle.enabled?(:legacy_mst_pact_identification) && editable?
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

  def editable_by_ssc_team_member?
    SupervisorySeniorCouncil.singleton.users.include?(user) &&
      FeatureToggle.enabled?(:split_appeal_workflow)
  end

  # editable option added for MST and PACT editing
  def editable_by_cob_team_member?
    ClerkOfTheBoard.singleton.users.include?(user) &&
      mst_pact_feature_toggles_enabled?
  end

  # returns true if one feature toggle is enabled
  def mst_pact_feature_toggles_enabled?
    FeatureToggle.enabled?(:mst_identification) ||
      FeatureToggle.enabled?(:pact_identification) ||
      FeatureToggle.enabled?(:legacy_mst_pact_identification)
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
