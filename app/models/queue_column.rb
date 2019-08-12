# frozen_string_literal: true

class QueueColumn
  include ActiveModel::Model

  def self.from_name(column_name)
    column = subclasses.find { |subclass| subclass.column_name == column_name }
    fail(Caseflow::Error::InvalidTaskTableColumn, column_name: column_name) unless column

    column
  end

  def self.column_name; end

  def name
    self.class.column_name
  end

  def sort_tasks(tasks, sort_order = Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC)
    # TODO: Improve the error we throw.
    valid_sort_orders = [Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC, Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC]
    fail(Caseflow::Error::MissingRequiredProperty, "invalid sort order") unless valid_sort_orders.include?(sort_order)

    unsafe_sort_tasks(tasks, sort_order)
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    tasks.order(created_at: sort_order)
  end

  def sort_by_cached_column(tasks, sort_order, *columns)
    order_clause = columns.map { |col| "#{CachedAppeal.table_name}.#{col} #{sort_order}" }.join(", ")
    tasks.joins(cached_attributes_join_clause).order(order_clause)
  end

  def cached_attributes_join_clause
    "left join #{CachedAppeal.table_name} "\
    "on #{CachedAppeal.table_name}.appeal_id = #{Task.table_name}.appeal_id "\
    "and #{CachedAppeal.table_name}.appeal_type = #{Task.table_name}.appeal_type"
  end
end

require_dependency "appeal_type_column"
require_dependency "case_details_link_column"
require_dependency "days_on_hold_column"
require_dependency "days_waiting_column"
require_dependency "docket_number_column"
require_dependency "document_count_reader_link_column"
require_dependency "hearing_badge_column"
require_dependency "issue_count_column"
require_dependency "regional_office_column"
require_dependency "task_assignee_column"
require_dependency "task_assigner_column"
require_dependency "task_closed_date_column"
require_dependency "task_due_date_column"
require_dependency "task_hold_length_column"
require_dependency "task_type_column"
