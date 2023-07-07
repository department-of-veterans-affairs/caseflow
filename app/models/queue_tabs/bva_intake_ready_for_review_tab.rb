# frozen_string_literal: true

class BvaIntakeReadyForReviewTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_READY_FOR_REVIEW_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.BVA_READY_FOR_REVIEW_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_BVA_READY_FOR_REVIEW_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    active_tasks.includes(*task_includes).joins(:ama_appeal)
  end

  def column_names
    BvaIntake::COLUMN_NAMES
  end

  def default_sorting_column
    QueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.RECEIPT_DATE_INTAKE.name)
  end
end
