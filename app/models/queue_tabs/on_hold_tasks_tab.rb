# frozen_string_literal: true

class OnHoldTasksTab < QueueTab
  def label
    COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.ON_HOLD_TASKS_TAB_NAME
  end

  def description
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.on_hold.where(parent: on_hold_tasks)
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
      show_regional_office_column ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
      Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
    ].compact
  end
end
