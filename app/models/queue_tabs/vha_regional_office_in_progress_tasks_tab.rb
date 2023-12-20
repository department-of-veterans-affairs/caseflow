# frozen_string_literal: true

class VhaRegionalOfficeInProgressTasksTab < QueueTab
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
    in_progress_tasks
  end

  def column_names
    VhaRegionalOffice::COLUMN_NAMES
  end
end
