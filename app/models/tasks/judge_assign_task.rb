class JudgeAssignTask < JudgeTask
  def available_actions(_user)
    [
      Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    ]
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
