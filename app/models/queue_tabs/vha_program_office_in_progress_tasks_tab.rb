# frozen_string_literal: true

class VhaProgramOfficeInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.VHA_PO_IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view
      .in_progress
      .where(assigned_to: assignee)
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
