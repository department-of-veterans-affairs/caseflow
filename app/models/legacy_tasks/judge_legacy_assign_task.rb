# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  def available_actions(user, _role)
    if assigned_to == user && user.judge_in_vacols?
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
      ]
    elsif user.can_act_on_behalf_of_judges?
      [
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
      ]
    else
      []
    end
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
