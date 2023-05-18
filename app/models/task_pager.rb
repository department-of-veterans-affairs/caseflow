# frozen_string_literal: true

# Utility class to sort, filter, and paginate tasks for a given queue tab and assignee
class TaskPager
  include ActiveModel::Model

  validates :tab_name, presence: true
  validate :assignee_is_user_or_organization
  validate :sort_order_is_valid

  attr_accessor :assignee, :tab_name, :page, :sort_by, :sort_order, :filters

  TASKS_PER_PAGE = 15

  def initialize(args)
    super

    @page ||= 1
    @sort_by ||= nil
    @sort_order ||= Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
    @filters ||= []

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def paged_tasks
    @paged_tasks ||= begin
      tasks = sorted_tasks(filtered_tasks)
      pagination_enabled ? tasks.page(page).per(TASKS_PER_PAGE) : tasks
    end
  end

  def sorted_tasks(tasks)
    column = QueueColumn.from_name(sort_by)
    TaskSorter.new(tasks: tasks, sort_order: sort_order, column: column, assignee: assignee).sorted_tasks
  end

  def task_page_count
    @task_page_count ||= pagination_enabled ? paged_tasks.total_pages : 1
  end

  def filtered_tasks
    TaskFilter.new(filter_params: filters, tasks: tasks_for_tab).filtered_tasks
  end

  def tasks_for_tab
    @tasks_for_tab ||= queue_tab.tasks
  end

  def total_task_count
    @total_task_count ||= pagination_enabled ? paged_tasks.total_count : paged_tasks.count
  end

  def queue_tab
    @queue_tab ||= QueueTab.from_name(tab_name).new(assignee: assignee)
  end

  def pagination_enabled
    @pagination_enabled ||= assignee.use_task_pages_api? && !queue_tab.contains_legacy_tasks?
  end

  private

  def assignee_is_user_or_organization
    unless assignee.is_a?(User) || assignee.is_a?(Organization)
      errors.add(:assignee, COPY::TASK_PAGE_INVALID_ASSIGNEE_MESSAGE)
    end
  end

  def sort_order_is_valid
    valid_sort_orders = [Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC, Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC]
    errors.add(:sort_order, COPY::TASK_PAGE_INVALID_SORT_ORDER) unless valid_sort_orders.include?(sort_order)
  end
end
