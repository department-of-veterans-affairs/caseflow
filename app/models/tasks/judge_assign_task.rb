class JudgeAssignTask < JudgeTask
  def baseline_actions
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
