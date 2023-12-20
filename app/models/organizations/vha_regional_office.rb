# frozen_string_literal: true

class VhaRegionalOffice < Organization
  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      assigned_tasks_tab,
      in_progress_tasks_tab,
      on_hold_tasks_tab,
      completed_tasks_tab
    ]
  end

  def assigned_tasks_tab
    ::VhaRegionalOfficeAssignedTasksTab.new(assignee: self)
  end

  def in_progress_tasks_tab
    ::VhaRegionalOfficeInProgressTasksTab.new(assignee: self)
  end

  def on_hold_tasks_tab
    ::VhaRegionalOfficeOnHoldTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::VhaRegionalOfficeCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
  ].compact
end
