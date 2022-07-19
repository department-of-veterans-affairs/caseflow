# frozen_string_literal: true

class EducationRpoAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_RPO_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    assigned_tasks
  end

  def column_names
    EducationRpo::COLUMN_NAMES
  end
end
