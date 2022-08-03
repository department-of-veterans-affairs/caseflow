# frozen_string_literal: true

class VhaCaregiverSupportUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.VHA_CAREGIVER_SUPPORT_UNASSIGNED_TASK_TAB_NAME
  end

  def description
    format(COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Tasks.includes(*task_includes).
    visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def column_names
    if show_reader_link_column
      COLUMN_NAMES.append(Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name)
    end
    COLUMN_NAMES
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name,
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
  ].compact
end