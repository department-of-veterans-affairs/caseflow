# frozen_string_literal: true

class CorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  def label
    "Assigned"
  end

  def self.tab_name
    "correspondence_assigned"
  end

  def description
    "Correspondence assigned to you:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to_id: assignee.id)
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
