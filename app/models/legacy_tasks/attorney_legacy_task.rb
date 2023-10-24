# frozen_string_literal: true

class AttorneyLegacyTask < LegacyTask
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, :reek:FeatureEnvy
  def available_actions(current_user, role)
    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table or is being used as a Case Movement action.
    # task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.

    action_array = []
    if case_movement_blocked_for_distribution?(current_user)
      action_array.push(Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT_LEGACY.to_h)
    elsif case_movement_ready_for_distribution?(current_user)
      action_array.push(Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT_LEGACY.to_h)
    end

    if task_id.nil?

    elsif attorney_user?(current_user, role)
      action_array.push(Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h)
      action_array.push(Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h)
      action_array.push(Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h)
    elsif ssc_legacy_case_movement?(current_user)
      action_array.push(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h)
    end
    action_array
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize

  def attorney_user?(current_user, role)
    role == "attorney" && current_user == assigned_to
  end

  def ssc_legacy_case_movement?(current_user)
    current_user&.can_act_on_behalf_of_legacy_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal)
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

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def actions_allowable?(_user)
    true
  end

  def label
    return false if appeal.case_record.nil?

    if (%w[81 57
           33].include?(appeal.case_record.reload.bfcurloc) || appeal.case_record.reload.bfcurloc == "CASEFLOW") &&
       FeatureToggle.enabled?(:vlj_legacy_appeal)
      COPY::ATTORNEY_REWRITE_TASK_LEGACY_LABEL
    else
      COPY::ATTORNEY_TASK_LABEL
    end
  end
end
