# frozen_string_literal: true

class OrganizationTrackingTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::TRACKING_TASKS_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME
  end

  def description
    format(COPY::TRACKING_TASKS_TAB_DESCRIPTION, assignee.name)
  end

  def tasks
    TrackVeteranTask.includes(*task_includes).active.where(assigned_to: assignee)
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name
    ]
  end
end
