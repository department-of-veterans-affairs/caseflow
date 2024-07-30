# frozen_string_literal: true

# organization representing the Regional Processing Offices within the Education business line.

class EducationRpo < Organization
  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      assigned_tasks_tab,
      in_progress_tab,
      completed_tasks_tab
    ]
  end

  def assigned_tasks_tab
    ::EducationRpoAssignedTasksTab.new(assignee: self)
  end

  def in_progress_tab
    ::EducationRpoInProgressTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::EducationRpoCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_OWNER.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name
  ].compact
end
