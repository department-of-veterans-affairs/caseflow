class TaskAction < ApplicationRecord
  enum status_after: {
    assigned: "assigned",
    in_progress: "in_progress",
    on_hold: "on_hold",
    completed: "completed"
  }

  def act(task, child_task_assignee_id)
    update_task_status(task)
    create_child_task(task, child_task_assignee_id)
  end

  def update_task_status(task)
    return unless status_after

    case status_after
    when "completed"
      task.mark_complete!
    when "on_hold"
      task.update(status: :on_hold)
    end
  end

  def create_child_task(task, child_task_assignee_id)
    return unless child_task_type

    Task.create!(
      appeal_id: task.appeal_id,
      assigned_by_id: task.assigned_to_id,
      appeal_type: task.appeal_type,
      parent_id: task.id,
      assigned_to_id: child_task_assignee_id,
      assigned_to_type: child_task_assignee_type
    )
  end
end
