# frozen_string_literal: true

class VhaCamoAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAMO_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_ASSIGNED_TO_DESCRIPTION, assignee.name)
  end

  def tasks
    active_tasks
  end

  def column_names
    VhaCamo::COLUMN_NAMES
  end
end
