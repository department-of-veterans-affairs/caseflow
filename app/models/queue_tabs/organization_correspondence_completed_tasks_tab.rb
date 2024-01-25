# frozen_string_literal: true

class OrganizationCorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Completed"
  end

  def self.tab_name
    "correspondence_team_completed"
  end

  def description
    "Completed correspondence:"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).recently_completed
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
