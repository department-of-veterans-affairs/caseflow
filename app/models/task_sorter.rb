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

    # Default to sorting by AOD, case type, and docket number.
    @column ||= QueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name)
    @sort_order ||= Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
    @tasks ||= Task.none

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def sorted_tasks
    return tasks unless tasks.any?

    # Always join to the CachedAppeal and users tables because we sometimes need it, joining does not slow down the
    # application, and conditional logic to only join sometimes adds unnecessary complexity.
    tasks.with_assignees.with_assigners.with_cached_appeals.order(order_clause)
  end

  private

  # some columns cannot be cast through SQL UPPER for normalized sorting.
  def sort_requires_case_norm?(col)
    return false if col.match?(/_at$/) # no timestamps
    return false if col.match?(/^is_/) # no booleans
    return false if col.match?(/_count$/) # no integers

    true
  end

  def order_clause
    case column.name
    when Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name
      Task.order_by_appeal_priority_clause(order: sort_order)
    when Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name
      Arel.sql(task_type_order_clause)
    when Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name
      Arel.sql(assigner_order_clause)
    else
      Arel.sql(default_order_clause)
    end
  end

  def default_order_clause
    clauses = column.sorting_columns.map do |col|
      tbl_clause = if sort_requires_case_norm?(col)
                     "UPPER(#{column.sorting_table}.#{col})"
                   else
                     "#{column.sorting_table}.#{col}"
                   end
      "#{tbl_clause} #{sort_order}"
    end
    clauses.join(", ")
  end

  # Sort tasks by their labels, rather than by type. Constructs a string of all task types sorted by their labels for
  # postgres to use as a reference for sorting as a task's label is not stored in the database.
  def task_type_order_clause
    task_types_sorted_by_label = Task.descendants.sort_by(&:label).map(&:name)
    task_types_sql_array = "array#{task_types_sorted_by_label}::varchar[]".tr('"', "'")
    task_type_sort_position = "#{task_types_sql_array}, tasks.type"
    "array_position(#{task_type_sort_position}) #{sort_order}"
  end

  def assigner_order_clause
    "substring(assigners.display_name,\'([a-zA-Z]+)$\') #{sort_order}"
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
