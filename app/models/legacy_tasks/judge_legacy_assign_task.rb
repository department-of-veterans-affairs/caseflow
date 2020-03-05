# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  def available_actions(user, role)
    if assigned_to == user && role == "judge"
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
      ]
    else
      return [] unless user.member_of_organization?(SpecialCaseMovementTeam.singleton) && FeatureToggle.enabled?(:scm_view_judge_assign_queue)
      [Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h]
    end
  end

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end
end
