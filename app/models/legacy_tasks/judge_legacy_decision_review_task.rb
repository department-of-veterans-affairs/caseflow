# frozen_string_literal: true

class JudgeLegacyDecisionReviewTask < JudgeLegacyTask
  def review_action
    Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
  end

  def reassign_action
    if FeatureToggle.enabled?(:legacy_case_movement_vlj_to_vlj_for_evalnsign)
      Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
    end
  end

  def available_actions(current_user, _role)
    # This must check judge_in_vacols? rather than role as judge, otherwise acting
    # VLJs cannot check out
    return [] if current_user != assigned_to || !current_user.judge_in_vacols?

    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      review_action,
      reassign_action
    ]
  end

  def label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
