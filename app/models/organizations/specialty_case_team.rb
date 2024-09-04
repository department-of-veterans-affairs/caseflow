# frozen_string_literal: true

# The Specialty Case Team (SCT)
#
# A single organization within the Board of Veteran Appeals (BVA).
# Established to increase efficiency in decision-writing for appeals with rare issues.
# Cases with rare issues are assigned to specific attorneys that specialize in particular legal topic areas.

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end

  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
      action_required_tasks_tab,
      completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    ::SpecialtyCaseTeamUnassignedTasksTab.new(assignee: self)
  end

  def action_required_tasks_tab
    ::SpecialtyCaseTeamActionRequiredTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::SpecialtyCaseTeamCompletedTasksTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
  ].compact
end
