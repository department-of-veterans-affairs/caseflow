# frozen_string_literal: true

class VhaCamoCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign
  delegate :column_names, to: :vha_camo

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def vha_camo
    @vha_camo || VhaCamo.new
  end
end
