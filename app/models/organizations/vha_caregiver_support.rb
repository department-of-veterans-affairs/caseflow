# frozen_string_literal: true

# The VHA Caregiver Support Program Office

class VhaCaregiverSupport < Organization
  def self.singleton
    VhaCaregiverSupport.first || VhaCaregiverSupport.create(name: "VHA Caregiver Support Program", url: "vha-csp")
  end

  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    []
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
  ].compact
end
