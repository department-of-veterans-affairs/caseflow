# frozen_string_literal: true

class BusinessLineInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    "In progress tasks"
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.BUSINESS_LINE_IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    "Review each issue and select a disposition"
  end

  def tasks
    BusinessLineTask.assigned_to(assignee).assigned
  end

  def column_names
    BusinessLine::COLUMN_NAMES
  end
end
