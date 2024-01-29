# frozen_string_literal: true

class OrganizationCorrespondenceUnassignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Unassigned"
  end

  def self.tab_name
    "correspondence_unassigned"
  end

  def description
    "Correspondence owned by the Mail team are unassigned to an individual:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee, status: "unassigned")
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name,
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
