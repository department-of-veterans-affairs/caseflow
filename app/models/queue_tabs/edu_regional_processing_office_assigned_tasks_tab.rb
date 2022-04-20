# frozen_string_literal: true

class EduRegionalProcessingOfficeAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATION_QUEUE_TABLE_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDU_REGIONAL_PROCESSING_OFFICE_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    assigned_tasks
  end

  def column_names
    EduRegionalProcessingOffice::COLUMN_NAMES
  end
end