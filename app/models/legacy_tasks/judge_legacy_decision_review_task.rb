# frozen_string_literal: true

class JudgeLegacyDecisionReviewTask < JudgeLegacyTask
  def review_action
    Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
  end

  def available_actions(current_user, _role)
    # This must check judge_in_vacols? rather than role as judge, otherwise acting
    # VLJs cannot check out
    return [] if current_user != assigned_to || !current_user.judge_in_vacols?

    actions = [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      review_action
    ]

    if SpecialCaseMovementTeam.singleton.user_has_access?(current_user)
      actions << Constants.TASK_ACTIONS.LEGACY_RETURN_TO_ATTORNEY.to_h
    end

    actions
  end

  def label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
