# frozen_string_literal: true

# The VHA Caregiver Support Program Office
#
# Although technically a program office within VHA, in almost all facets operates
# more similarly to the VhaCamo org as opposed to the other VhaProgramOffice orgs.
#
# Unlike other POs, this organization will receive appeals directly from Intake and
# be able to interact with BVA Intake directly without having to go through VHA CAMO
# as an intermediary.

class VhaCaregiverSupport < Organization
  def self.singleton
    VhaCaregiverSupport.first || VhaCaregiverSupport.create(name: "VHA Caregiver Support Program", url: "vha-csp")
  end

  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
      in_progress_tasks_tab,
      completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    ::VhaCaregiverSupportUnassignedTasksTab.new(assignee: self)
  end

  def in_progress_tasks_tab
    ::VhaCaregiverSupportInProgressTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::VhaCaregiverSupportCompletedTasksTab.new(assignee: self)
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
