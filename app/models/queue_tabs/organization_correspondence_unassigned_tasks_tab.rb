# frozen_string_literal: true

class OrganizationCorrespondenceUnassignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).unassigned_tasks
  end

  # :reek:UtilityFunction
  def self.column_names
    user = RequestStore.store[:current_user]
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
    columns.insert(0, Constants.QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name) unless user.inbound_ops_team_superuser?
    columns
  end
end
