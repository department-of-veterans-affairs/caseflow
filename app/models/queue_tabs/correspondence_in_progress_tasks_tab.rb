# frozen_string_literal: true

class CorrespondenceInProgressTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  def label
    "In Progress"
  end

  def self.tab_name
    "correspondence_in_progress"
  end

  def description
    "Correspondence in progress that are assigned to you:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee).in_progress
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
