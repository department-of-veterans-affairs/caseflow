# frozen_string_literal: true

class TrackingTasksTab < QueueTab
  def label
    COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE
  end

  def name
    Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME
  end

  def description
    COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION
  end

  def columns
    [
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
    ]
  end
end
