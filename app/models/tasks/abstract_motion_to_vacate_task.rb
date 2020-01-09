# frozen_string_literal: true

# This serves as a parent to other tasks that are spawned from `JudgeAddressMotionToVacateTask`
# We don't want to ever come back to the judge task, so we don't want to add children on it
class AbstractMotionToVacateTask < Task
  def hide_from_task_snapshot
    true
  end

  def update_status_if_children_tasks_are_closed(_child_task)
    if children.any? && children.open.empty? && on_hold?
      all_children_cancelled_or_completed

      #  Ensure the parent VacateMotionMailTask gets closed out
      parent.update!(status: status)
    end
  end

  def child_must_have_active_assignee?
    false
  end
end
