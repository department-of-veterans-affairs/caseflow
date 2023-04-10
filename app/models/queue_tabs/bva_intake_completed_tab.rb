# frozen_string_literal: true

class BvaIntakeCompletedTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.BVA_INTAKE_COMPLETED_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).completed.joins(:ama_appeal)
  end

  def column_names
    BvaIntake::COLUMN_NAMES
  end

  def default_sorting_column
    QueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.RECEIPT_DATE_INTAKE.name)
  end
end
