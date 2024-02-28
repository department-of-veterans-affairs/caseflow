# frozen_string_literal: true

class AssignLegacyTask < LegacyTask
  def timeline_title
    COPY::CASE_TIMELINE_ASSIGN_LEGACY_TASK
  end

  def label
    COPY::ASSIGN_LEGACY_TASK_LABEL
  end

  def available_actions(_current_user, _role)
    [
      Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h,
      Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    ]
  end
end
