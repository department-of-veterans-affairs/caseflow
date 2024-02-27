# frozen_string_literal: true

##
# Task to complete a case or assign it to an attorney after it's returned to the judge by the dispatch team.

class JudgeDispatchReturnTask < JudgeTask
  def additional_available_actions(_user)
    [
      Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h,
      Constants.TASK_ACTIONS.JUDGE_DISPATCH_RETURN_TO_ATTORNEY.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def self.label
    COPY::JUDGE_DISPATCH_RETURN_TASK_LABEL
  end
end
