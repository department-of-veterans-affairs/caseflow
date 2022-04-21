# frozen_string_literal: true

class EduRegionalProcessingOffice < Organization
  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      completed_tasks_tab
    ]
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
