# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  def available_actions(user, role)
    if user&.can_act_on_behalf_of_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal) &&
       (appeal.case_record.reload.bfcurloc == "57" || appeal.case_record.reload.bfcurloc == "CASEFLOW")
      [
        Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT_LEGACY.to_h
      ]
    elsif user&.can_act_on_behalf_of_judges? && FeatureToggle.enabled?(:vlj_legacy_appeal) &&
          %w[81 33].include?(appeal.case_record.reload.bfcurloc)
      [
        Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT_LEGACY.to_h
      ]
    elsif assigned_to == user && role == "judge"
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
      ]
    elsif user.can_act_on_behalf_of_judges? && assigned_to.judge_in_vacols?
      [
        Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h
      ]
    else
      []
    end
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
