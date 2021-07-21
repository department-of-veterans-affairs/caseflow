# frozen_string_literal: true

##
# Task for a judge to review decisions.
# A JudgeDecisionReviewTask implies that there is a decision that needs to be reviewed from an attorney.
# The case associated with this task appears in the judge's Cases to review view
# There should only ever be one open JudgeDecisionReviewTask at a time for an appeal.
# If an AttorneyTask is cancelled, we would want to cancel both it and its parent JudgeDecisionReviewTask
# and create a new JudgeAssignTask, because another assignment by a judge is needed.

class JudgeDecisionReviewTask < JudgeTask
  before_create :verify_user_task_unique

  def additional_available_actions(user)
    return [] unless assigned_to == user

    judge_checkout_label = if ama?
                             ama_judge_actions
                           else
                             Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
                           end

    [
      (Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h if ama? && appeal.vacate?),
      judge_checkout_label,
      Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
    ].compact
  end

  def self.label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end

  # Use the existence of another open JudgeDecisionReviewTask to prevent duplicates since there should only
  # ever be one open JudgeDecisionReviewTask at a time for an appeal.
  def verify_user_task_unique
    return if !open?

    if appeal.tasks.open.where(
      type: type,
      assigned_to: assigned_to,
      parent: parent
    ).any? && assigned_to.is_a?(User)
      fail(
        Caseflow::Error::DuplicateUserTask,
        docket_number: appeal.docket_number,
        task_type: self.class.name
      )
    end
  end

  private

  def ama_judge_actions
    Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT_SP_ISSUES.to_h
  end
end
