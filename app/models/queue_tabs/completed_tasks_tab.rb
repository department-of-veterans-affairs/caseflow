# frozen_string_literal: true

class CompletedTasksTab < QueueTab
  def label
    COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE
  end

  def name
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
  end

  def columns
    [
      Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
      show_regional_office_column ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
      Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN
    ].compact
  end
end
