# frozen_string_literal: true

class TaskAssignerColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.TASK_ASSIGNER_COLUMN
  end
end
