# frozen_string_literal: true

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
    sorted_tasks(filtered_tasks).page(page).per(TASKS_PER_PAGE)
  end

  def sorted_tasks(tasks)
    QueueColumn.from_name(sort_by).new.sort_tasks(tasks, sort_order)
  end

  def task_page_count
    @task_page_count ||= paged_tasks.total_pages
  end

  def filtered_tasks
    where_clause = QueueWhereClauseArgumentsFactory.new(filter_params: filters).arguments
    where_clause.empty? ? tasks_for_tab : tasks_for_tab.joins(cached_attributes_join_clause).where(*where_clause)
  end

  def tasks_for_tab
    QueueTab.from_name(tab_name).new(assignee: assignee).tasks
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
