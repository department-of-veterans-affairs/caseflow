# frozen_string_literal: true

class VhaCamoInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGESS_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  # rubocop:disable Metrics/AbcSize
  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    ].compact
  end
  # rubocop:enable Metrics/AbcSize
end
