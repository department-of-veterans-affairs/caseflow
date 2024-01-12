# frozen_string_literal: true

# organization representing the VHA Claims and Appeals Modernization Office

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end

  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      action_required_tab,
      completed_tab
    ]
  end

  def action_required_tab
    ::SpecialtyCaseTeamActionRequiredTasksTab.new(assignee: self)
  end

  def completed_tab
    ::SpecialtyCaseTeamCompletedTasksTab.new(assignee: self)
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
