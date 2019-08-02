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
    @sort_by ||= Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN
    @sort_order ||= Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
    @filters ||= []

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def paged_tasks
    # TODO: Validate input.
    # TODO: Ensure no filters works correctly.
    where_clause = filter_params_to_where_clause(filters)
    filtered_tasks = tasks_for_tab.where(where_clause)
    sorted_tasks(filtered_tasks).page(page).per(TASKS_PER_PAGE)
  end

  def sorted_tasks(tasks)
    case sort_by
    when Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN, Constants.QUEUE_CONFIG.TASK_DUE_DATE_COLUMN
      tasks.order(assigned_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_CLOSED_DATE_COLUMN
      tasks.order(closed_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
      tasks.order(type: sort_order, action: sort_order, created_at: sort_order)
    when Constants.QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN
      tasks.order(placed_on_hold_at: sort_order)
    # Columns not yet supported:
    #
    # APPEAL_TYPE_COLUMN
    # CASE_DETAILS_LINK_COLUMN
    # DAYS_ON_HOLD_COLUMN
    # DOCUMENT_COUNT_READER_LINK_COLUMN
    # DOCKET_NUMBER_COLUMN
    # HEARING_BADGE_COLUMN
    # ISSUE_COUNT_COLUMN
    # REGIONAL_OFFICE_COLUMN
    # TASK_ASSIGNEE_COLUMN
    # TASK_ASSIGNER_COLUMN
    #
    else
      tasks.order(created_at: sort_order)
    end
  end

  # Assuming columns filtered on multiple values are comma-separated.
  # ["col=docketNumberColumn&val=legacy,evidence_submission", "col=taskColumn&val=translation"]
  # ->
  # "cached_appeals_attributes.docket_type IN ('legacy', 'evidence_submission') AND
  #   cached_appeals_attributes.task_action IN ('translation')"
  def self.filter_params_to_where_clause(filter_params)
    filter_params.map do |filter_string|
      # TODO: filter is a string. Let's make it a hash!
      filter_hash = Rack::Utils.parse_query(filter_string)
      values = filter_hash["val"].split(",")

      "#{table_column_from_name(filter_hash['col'])} IN #{values}"
    end.join(" AND ")
  end

  def self.table_column_from_name(column_name)
    case column_name
    # TODO: I think this constant may be incorrectly named.
    when Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
      "cached_appeals_attributes.docket_type"
    when Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
      "tasks.type"
    # TODO: The following columns are not yet implemented.
    # when Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
    #   "cached_appeals_attributes.appeal_type"
    # when Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
    #   "cached_appeals_attributes.regional_office"
    # when Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN
    #   "???"
    else
      fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
    end
  end

  def task_page_count
    @task_page_count ||= paged_tasks.total_pages
  end

  def total_task_count
    @total_task_count ||= tasks_for_tab.count
  end

  def tasks_for_tab
    case tab_name
    when Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME
      tracking_tasks
    when Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME
      active_tasks
    when Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME
      assigned_child_tasks
    when Constants.QUEUE_CONFIG.ON_HOLD_TASKS_TAB_NAME
      on_hold_child_tasks
    when Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
      recently_completed_tasks
    else
      fail(Caseflow::Error::InvalidTaskTableTab, tab_name: tab_name)
    end
  end

  private

  def tracking_tasks
    TrackVeteranTask.includes(*task_includes).active.where(assigned_to: assignee)
  end

  def active_tasks
    Task.includes(*task_includes)
      .visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def on_hold_tasks
    Task.includes(*task_includes)
      .visible_in_queue_table_view.where(assigned_to: assignee).on_hold
  end

  def assigned_child_tasks
    Task.includes(*task_includes)
      .visible_in_queue_table_view.active.where(parent: on_hold_tasks)
  end

  def on_hold_child_tasks
    Task.includes(*task_includes)
      .visible_in_queue_table_view.on_hold.where(parent: on_hold_tasks)
  end

  def recently_completed_tasks
    Task.includes(*task_includes)
      .visible_in_queue_table_view.where(assigned_to: assignee).recently_closed
  end

  def assignee_is_user_or_organization
    unless assignee.is_a?(User) || assignee.is_a?(Organization)
      errors.add(:assignee, COPY::TASK_PAGE_INVALID_ASSIGNEE_MESSAGE)
    end
  end

  def sort_order_is_valid
    valid_sort_orders = [Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC, Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC]
    errors.add(:sort_order, COPY::TASK_PAGE_INVALID_SORT_ORDER) unless valid_sort_orders.include?(sort_order)
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end
end
