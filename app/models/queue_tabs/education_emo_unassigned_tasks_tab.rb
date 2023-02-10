# frozen_string_literal: true

class EducationEmoUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_EMO_UNASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  # In each case, if the EMO task is assigned, then it should meet each use case for the unassigned tab
  def tasks
    active_tasks
  end

  # Column names defined in each tab in education predocket due to different columns needed
  # Actual names found in QUEUE_CONFIG.json file
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
    Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name
  ].compact
end
