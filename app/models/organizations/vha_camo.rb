# frozen_string_literal: true

class VhaCamo < Organization
  def self.singleton
    VhaCamo.first || VhaCamo.create(name: "VHA CAMO", url: "vha-camo")
  end

  def queue_tabs
    [
      in_progress_tasks_tab,
      completed_tasks_tab
    ]
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
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name
  ].compact
end
