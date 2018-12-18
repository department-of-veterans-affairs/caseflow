class JudgeAssignTask < JudgeTask
  def available_actions(_user)
    actions = [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
    actions << Constants.TASK_ACTIONS.MARK_COMPLETE.to_h if parent && parent.is_a?(QualityReviewTask)

    actions
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
