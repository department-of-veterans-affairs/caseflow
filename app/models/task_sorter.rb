# frozen_string_literal: true

class TaskSorter
  include ActiveModel::Model

  validates :column, :sort_order, presence: true
  validate :column_is_valid
  validate :sort_order_is_valid

  attr_accessor :column, :sort_order, :tasks

  def initialize(args)
    super

    # Default to sorting by task creation date.
    @column ||= TaskCreatedAtColumn
    @sort_order ||= Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
    @tasks ||= []

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def sorted_tasks
    return tasks unless tasks.any?

    # Always join to the CachedAppeal table because we sometimes need it, joining does not slow down the application,
    # and conditional logic to only join sometimes adds unnecessary complexity.
    tasks.joins(cached_attributes_join_clause).order(order_clause)
  end

  private

  def order_clause
    column.sorting_columns.map { |col| "#{column.sorting_table}.#{col} #{sort_order}" }.join(", ")
  end

  def cached_attributes_join_clause
    "left join #{CachedAppeal.table_name} "\
    "on #{CachedAppeal.table_name}.appeal_id = #{Task.table_name}.appeal_id "\
    "and #{CachedAppeal.table_name}.appeal_type = #{Task.table_name}.appeal_type"
  end

  def column_is_valid
    # Use include?() instead of is_a?() because column is a class, not an instance.
    errors.add(:column, COPY::INVALID_SORT_COLUMN) unless QueueColumn.subclasses.include?(column)
  end

  def sort_order_is_valid
    valid_sort_orders = [Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC, Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC]
    errors.add(:sort_order, COPY::TASK_PAGE_INVALID_SORT_ORDER) unless valid_sort_orders.include?(sort_order)
  end
end
