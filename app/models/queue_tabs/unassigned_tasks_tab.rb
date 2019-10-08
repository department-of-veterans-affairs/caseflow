# frozen_string_literal: true

class UnassignedTasksTab < QueueTab
  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
      show_regional_office_column ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
      Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN,
      show_reader_link_column ? Constants.QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN : nil
    ].compact
  end

  def allow_bulk_assign?
    !!allow_bulk_assign
  end
end
