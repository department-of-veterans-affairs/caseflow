# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  def available_actions(current_user, role)
    return [] if role != "judge" || current_user != assigned_to

    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
      Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
    ]
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
