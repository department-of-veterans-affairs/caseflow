# frozen_string_literal: true

class VhaCaregiverSupportUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_UNASSIGNED_TASK_TAB_NAME
  end

  def description
    format(COPY::VHA_CAREGIVER_SUPPORT_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).assigned
  end

  def column_names
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
