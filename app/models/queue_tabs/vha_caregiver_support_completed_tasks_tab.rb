# frozen_string_literal: true

class VhaCaregiverSupportCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign
  delegate :column_names, to: :vha_caregiver_support

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_COMPLETED_TASKS_TAB_NAME
  end

  def description
    format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    recently_completed_tasks
  end

  def column_names
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
