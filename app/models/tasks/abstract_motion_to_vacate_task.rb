# frozen_string_literal: true

# This serves as a parent to other tasks that are spawned from `JudgeAddressMotionToVacateTask`
# We don't want to ever come back to the judge task, so we don't want to add children on it
class AbstractMotionToVacateTask < Task
  def hide_from_task_snapshot
    true
  end
end
