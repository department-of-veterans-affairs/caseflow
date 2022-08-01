# frozen_string_literal: true

class VhaCaregiverSupportInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  # attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TAB_TITLE
  end

  def self.tab_name
    # Constants.QUEUE_CONFIG.CAMO_IN_PROGRESS_TASKS_TAB_NAME
    Constants.QUEUE.CONFIG.CAREGIVER_SUPPORT_IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_IN_PROGRESS_TASKS_DESCRIPTION
  end

  def tasks
    in_progress_tasks
  end

  def column_names
    # might change depending on required columns
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
