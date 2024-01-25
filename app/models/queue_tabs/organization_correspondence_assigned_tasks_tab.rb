# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Assigned"
  end

  def self.tab_name
    "correspondence_team_assigned"
  end

  def description
    "Correspondence that is currently assigned to mail team users:"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).assigned
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name,
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
