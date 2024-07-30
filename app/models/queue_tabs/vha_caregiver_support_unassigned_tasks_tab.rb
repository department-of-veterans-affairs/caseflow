# frozen_string_literal: true

class VhaCaregiverSupportUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_UNASSIGNED_TASK_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_ASSIGNED_TO_DESCRIPTION, assignee.name)
  end

  def tasks
    assigned_tasks
  end

  def column_names
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
