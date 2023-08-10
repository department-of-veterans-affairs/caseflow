# frozen_string_literal: true

class AttorneyLegacyTask < LegacyTask
  def available_actions(current_user, role)
    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table. task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.
    return [] unless task_id

    if current_user&.can_act_on_behalf_of_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal) &&
       (appeal.case_record.reload.bfcurloc == "57" || appeal.case_record.reload.bfcurloc == "CASEFLOW")
      [
        Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT_LEGACY.to_h
      ]
    elsif current_user&.can_act_on_behalf_of_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal) &&
          %w[81 33].include?(appeal.case_record.reload.bfcurloc)
      [
        Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT_LEGACY.to_h
      ]
    elsif (current_user&.judge_in_vacols? || current_user&.can_act_on_behalf_of_judges?) &&
          FeatureToggle.enabled?(:vlj_legacy_appeal)
      [
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h
      ]
    elsif role == "attorney" && current_user == assigned_to
      [
        Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
        Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h
      ]
    else
      []
    end
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
