# frozen_string_literal: true

##
# Task for to complete a case or assign it to an attorney after it's returned to the judge by the quality review team.

class JudgeQualityReviewTask < JudgeTask
  def additional_available_actions(_user)
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h, Constants.TASK_ACTIONS.MARK_COMPLETE.to_h]
  end

  def label
    COPY::JUDGE_QUALITY_REVIEW_TASK_LABEL
  end
end
