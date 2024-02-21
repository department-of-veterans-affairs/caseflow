# frozen_string_literal: true

class CorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_COMPLETED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_COMPLETED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_COMPLETED_TASKS_DESCRIPTION
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee).recently_completed
  end

  # :reek:UtilityFunction
  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
