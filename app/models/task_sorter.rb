# frozen_string_literal: true

class TaskSorter
  include ActiveModel::Model

  validates :column, :sort_order, presence: true
  validate :column_is_valid
  validate :sort_order_is_valid
  validate :tasks_type_is_valid

  attr_accessor :column, :sort_order, :tasks

  def initialize(args)
    super

    # Default to sorting by task creation date.
    @column ||= QueueColumn.from_name(Constants.QUEUE_CONFIG.TASK_CREATED_AT_COLUMN)
    @sort_order ||= Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
    @tasks ||= Task.none

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def sorted_tasks
    return tasks unless tasks.any?

    # Always join to the CachedAppeal table because we sometimes need it, joining does not slow down the application,
    # and conditional logic to only join sometimes adds unnecessary complexity.
    tasks.joins(CachedAppeal.left_join_from_tasks_clause).order(order_clause)
  end

  private

  def order_clause
    column.sorting_columns.map { |col| "#{column.sorting_table}.#{col} #{sort_order}" }.join(", ")
  end

  def column_is_valid
    errors.add(:column, COPY::INVALID_SORT_COLUMN) unless column.is_a?(QueueColumn)
  end

  def sort_order_is_valid
    valid_sort_orders = [Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC, Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC]
    errors.add(:sort_order, COPY::TASK_PAGE_INVALID_SORT_ORDER) unless valid_sort_orders.include?(sort_order)
  end

  def tasks_type_is_valid
    errors.add(:tasks, COPY::INVALID_TASKS_ARGUMENT) unless tasks.is_a?(ActiveRecord::Relation)
  end
end
