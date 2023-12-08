# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  # rubocop:disable Metrics/AbcSize, :reek:FeatureEnvy
  def available_actions(current_user, role)
    action_array = []
    if case_movement_blocked_for_distribution?(current_user)
      action_array.push(Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT_LEGACY.to_h)
    elsif case_movement_ready_for_distribution?(current_user)
      action_array.push(Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT_LEGACY.to_h)
    end

    if judge_user?(current_user, role)
      action_array.push(Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h)
      action_array.push(Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h)
      action_array.push(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h)
    elsif judge_case_movement?(current_user)
      action_array.push(Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h)
      action_array.push(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h)
    end

    action_array
  end
  # rubocop:enable Metrics/AbcSize

  def judge_user?(current_user, role)
    role == "judge" && current_user == assigned_to
  end

  def judge_case_movement?(current_user)
    current_user&.can_act_on_behalf_of_judges? && assigned_to.judge_in_vacols?
  end

  def legacy_case_movement?(current_user)
    current_user&.can_act_on_behalf_of_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal)
  end

  def appeal_not_ready_for_distribution?
    appeal.case_record.reload.bfcurloc == "57" || appeal.case_record.reload.bfcurloc == "CASEFLOW"
  end

  def case_movement_blocked_for_distribution?(current_user)
    legacy_case_movement?(current_user) && appeal_not_ready_for_distribution?
  end

  def case_movement_ready_for_distribution?(current_user)
    legacy_case_movement?(current_user) && appeal_ready_for_distribution?
  end

  def appeal_ready_for_distribution?
    %w[81 33].include?(appeal.case_record.reload.bfcurloc)
  end

  def label
    if (%w[81 57
           33].include?(appeal.case_record.reload.bfcurloc) || appeal.case_record.reload.bfcurloc == "CASEFLOW") &&
       FeatureToggle.enabled?(:vlj_legacy_appeal)
      COPY::ATTORNEY_REWRITE_TASK_LEGACY_LABEL
    else
      COPY::JUDGE_ASSIGN_TASK_LABEL
    end
  end
end
