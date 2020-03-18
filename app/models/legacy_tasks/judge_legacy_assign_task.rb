# frozen_string_literal: true

class JudgeLegacyAssignTask < JudgeLegacyTask
  def available_actions(user, role)
    if assigned_to == user && role == "judge"
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
      ]
    elsif member_of_scm?(user)
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

  private

  def member_of_scm?(user)
    user.member_of_organization?(SpecialCaseMovementTeam.singleton) &&
      FeatureToggle.enabled?(:scm_view_judge_assign_queue)
  end
end
