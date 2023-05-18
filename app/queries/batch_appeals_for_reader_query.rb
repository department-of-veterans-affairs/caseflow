# frozen_string_literal: true

class BatchAppealsForReaderQuery
  def self.process
    # Fetch tasks including the assigned_to user
    # Join with appeals where task.appeal_id matches appeal.id
    # group by assigned_to user
    Task.includes(:assigned_to)
      .joins("INNER JOIN appeals ON appeals.id = tasks.appeal_id")
      .where(status: Task.active_statuses, assigned_to_type: User.name, type: Task.reader_priority_task_types)
      .group_by(&:assigned_to)
  end
end
