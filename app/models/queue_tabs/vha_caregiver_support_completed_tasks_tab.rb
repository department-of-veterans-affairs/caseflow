# frozen_string_literal: true

class VhaCaregiverSupportCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_LAST_SEVEN_DAYS_TASKS_DESCRIPTION
  end

  def tasks
    recently_completed_tasks_without_younger_siblings
  end

  def column_names
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
