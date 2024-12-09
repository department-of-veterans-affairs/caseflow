# frozen_string_literal: true

# This task is used to provide Special Case Movement Team users the ability to manually
# advance a legacy appeal from the distribution pool to a Judge

class AssignmentLegacyTask < LegacyTask
  def timeline_title
    COPY::CASE_TIMELINE_ASSIGN_LEGACY_TASK
  end

  def label
    COPY::ASSIGN_LEGACY_TASK_LABEL
  end

  def available_actions(_current_user, _role)
    [
      Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h
    ]
  end
end
