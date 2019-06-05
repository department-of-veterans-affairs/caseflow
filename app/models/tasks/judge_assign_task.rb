# frozen_string_literal: true

##
# Task for a judge to assign tasks to attorneys.

class JudgeAssignTask < JudgeTask
  def additional_available_actions(_user)
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
