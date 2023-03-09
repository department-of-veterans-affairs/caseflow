# frozen_string_literal: true

class BusinessLineCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    "Completed tasks"
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.BUSINESS_LINE_COMPLETED_TASKS_TAB_NAME
  end

  def description
    "Review each issue and select a disposition"
  end

  def tasks
    BusinessLineTask.assigned_to(assignee).recently_completed
  end

  def column_names
    BusinessLine::COLUMN_NAMES.clone.tap do |columns|
      columns[
        columns.find_index(Constants.QUEUE_CONFIG.DECISION_REVIEW_QUEUE_COLUMNS.DAYS_WAITING.name)
      ] = Constants.QUEUE_CONFIG.DECISION_REVIEW_QUEUE_COLUMNS.TASK_CLOSED_DATE.name
    end
  end
end
