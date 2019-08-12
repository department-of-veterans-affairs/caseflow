# frozen_string_literal: true

class TaskAssigneeColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN
  end
end
