# frozen_string_literal: true

# organization representing the VHA Claims and Appeals Modernization Office

class VhaCamo < Organization
  def self.singleton
    VhaCamo.first || VhaCamo.create(name: "VHA CAMO", url: "vha-camo")
  end

  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      assigned_tasks_tab,
      in_progress_tasks_tab,
      completed_tasks_tab
    ]
  end

  def assigned_tasks_tab
    ::VhaCamoAssignedTasksTab.new(assignee: self)
  end

  def in_progress_tasks_tab
    ::VhaCamoInProgressTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::VhaCamoCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
  ].compact
end
