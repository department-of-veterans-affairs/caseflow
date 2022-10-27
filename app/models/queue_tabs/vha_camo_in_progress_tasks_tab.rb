# frozen_string_literal: true

class VhaCamoInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAMO_IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    COPY::VHA_ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TASKS_DESCRIPTION
  end

  def tasks
    on_hold_task_children.active
  end

  def column_names
    VhaCamo::COLUMN_NAMES
  end
end
