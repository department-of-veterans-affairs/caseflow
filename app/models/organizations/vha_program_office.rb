# frozen_string_literal: true

class VhaProgramOffice < Organization
  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      assigned_tasks_tab,
      in_progress_tasks_tab,
      ready_for_review_tasks_tab,
      on_hold_tasks_tab,
      completed_tasks_tab
    ]
  end

  def assigned_tasks_tab
    ::VhaProgramOfficeAssignedTasksTab.new(assignee: self)
  end

  def in_progress_tasks_tab
    ::VhaProgramOfficeInProgressTasksTab.new(assignee: self)
  end

  def ready_for_review_tasks_tab
    ::VhaProgramOfficeReadyForReviewTasksTab.new(assignee: self)
  end

  def on_hold_tasks_tab
    ::VhaProgramOfficeOnHoldTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::VhaProgramOfficeCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_OWNER.name,
    # Constants.QUEUE_CONFIG.COLUMNS.VAMC_OWNER.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.LAST_ACTION.name,
    Constants.QUEUE_CONFIG.COLUMNS.BOARD_INTAKE.name
  ].compact
end
