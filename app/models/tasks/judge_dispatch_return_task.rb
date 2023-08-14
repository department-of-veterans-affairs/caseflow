# frozen_string_literal: true

##
# Task to complete a case or assign it to an attorney after it's returned to the judge by the dispatch team.

class JudgeDispatchReturnTask < JudgeTask
  def additional_available_actions(_user)
    [
      ama_issue_checkout,
      Constants.TASK_ACTIONS.JUDGE_DISPATCH_RETURN_TO_ATTORNEY.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def self.label
    COPY::JUDGE_DISPATCH_RETURN_TASK_LABEL
  end

  def ama_issue_checkout
    # bypass special issues page if mst/pact enabled
    return Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h if
      FeatureToggle.enabled?(:mst_identification) || FeatureToggle.enabled?(:pact_identification)

    Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT_SPECIAL_ISSUES.to_h
  end
end
