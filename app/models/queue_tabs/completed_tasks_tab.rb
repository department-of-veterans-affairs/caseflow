# frozen_string_literal: true

class CompletedTasksTab < QueueTab
  validate :assignee_is_user

  def label
    COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.INDIVIDUALLY_COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
  end

  def tasks
    recently_completed_tasks
  end

  # rubocop:disable Metrics/AbcSize
  def column_names
    # check for attorney_in_vacols? first so that acting-VLJs will continue to see their attorney columns
    return QueueTab.attorney_column_names if assignee.attorney_in_vacols?
    return QueueTab.judge_column_names if assignee.judge_in_vacols?

    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      show_regional_office_column ? Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name : nil,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
    ].compact
  end
  # rubocop:enable Metrics/AbcSize
end
