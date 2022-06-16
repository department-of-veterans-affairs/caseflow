# frozen_string_literal: true

# Executive Management Office inside Education

class EducationEmo < Organization
  def self.singleton
    EducationEmo.first || EducationEmo.create(name: "Executive Management Office", url: "edu-emo")
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    ::EducationEmoUnassignedTasksTab.new(assignee: self)
  end

  def assigned_tasks_tab
    ::EducationEmoAssignedTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::EducationEmoCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
  ].compact
end
