# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    tasks = CorrespondenceTask.includes(*task_includes).package_action_tasks

    tasks = if RequestStore[:current_user].mail_supervisor?
      tasks.where(assigned_to: assignee).active
    else
      tasks.where.not(type: RemovePackageTask.name).where(assigned_to: assignee).active
    end
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name,
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
