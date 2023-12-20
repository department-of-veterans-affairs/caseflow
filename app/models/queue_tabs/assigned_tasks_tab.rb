# frozen_string_literal: true

# Queue tab for all tasks that are currently assigned to a user and have a status of "assigned" or "in_progress"
# Until judge assign queues are built from queue config, this tab will omit judge assign tasks
class AssignedTasksTab < QueueTab
  validate :assignee_is_user

  def label
    COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.active
      .where(assigned_to: assignee)
      .where.not(type: JudgeAssignTask.name)
  end

  def contains_legacy_tasks?
    assignee.can_be_assigned_legacy_tasks?
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
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
    ].compact
  end
  # rubocop:enable Metrics/AbcSize
end
