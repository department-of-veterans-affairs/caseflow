# frozen_string_literal: true
class BatchAppealsForReaderQuery
  def self.process
    Task.includes(:assigned_to)
      .joins("RIGHT JOIN appeals ON appeals.id = tasks.assigned_to_id AND tasks.assigned_to_type = 'User'")
      .where(status: Task.active_statuses, assigned_to_type: User.name, type: Task.reader_priority_task_types)
      .group_by(&:assigned_to)
  end
end
