# frozen_string_literal: true

class VhaProgramOfficeAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    byebug
    Task.includes(*task_includes).visible_in_queue_table_view
    .where(assigned_to: assignee)
    .assigned
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end

end
