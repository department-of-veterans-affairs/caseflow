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

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def sorted_tasks(tasks)
    case sort_by
    when Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN, Constants.QUEUE_CONFIG.TASK_DUE_DATE_COLUMN
      tasks.order(assigned_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_CLOSED_DATE_COLUMN
      tasks.order(closed_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
      tasks.order(type: sort_order, created_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN
      tasks.order(placed_on_hold_at: sort_order)
    when Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
      tasks_sorted_by_docket_number(tasks)
    when Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
      tasks_sorted_by_regional_office(tasks)
    when Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN
      tasks_sorted_by_issue_count(tasks)
    when Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN
      tasks_sorted_by_veteran_name(tasks)
    when Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
      tasks_sorted_by_appeal_case_type(tasks)

    # Columns not yet supported:
    #
    # DAYS_ON_HOLD_COLUMN
    # DOCUMENT_COUNT_READER_LINK_COLUMN
    # HEARING_BADGE_COLUMN
    # TASK_ASSIGNEE_COLUMN
    # TASK_ASSIGNER_COLUMN
    #
    else
      tasks_sorted_by_appeal_case_type(tasks)
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity

  def tasks_sorted_by_appeal_case_type(tasks)
    tasks.joins(cached_attributes_join_clause).order("cached_appeal_attributes.is_aod DESC, "\
                                                     "cached_appeal_attributes.case_type #{sort_order}, "\
                                                     "cached_appeal_attributes.docket_number #{sort_order}")
  end

  def tasks_sorted_by_docket_number(tasks)
    tasks.joins(cached_attributes_join_clause).order("cached_appeal_attributes.docket_type #{sort_order}, "\
                                                     "cached_appeal_attributes.docket_number #{sort_order}")
  end

  def tasks_sorted_by_regional_office(tasks)
    tasks.joins(cached_attributes_join_clause).order(
      "cached_appeal_attributes.closest_regional_office_city #{sort_order}"
    )
  end

  def tasks_sorted_by_issue_count(tasks)
    tasks.joins(cached_attributes_join_clause).order("cached_appeal_attributes.issue_count #{sort_order}")
  end

  def tasks_sorted_by_veteran_name(tasks)
    tasks.joins(cached_attributes_join_clause).order("cached_appeal_attributes.veteran_name #{sort_order}")
  end

  def cached_attributes_join_clause
    "left join cached_appeal_attributes "\
    "on cached_appeal_attributes.appeal_id = tasks.appeal_id "\
    "and cached_appeal_attributes.appeal_type = tasks.appeal_type"
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
