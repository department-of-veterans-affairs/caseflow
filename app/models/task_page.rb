# frozen_string_literal: true

class TaskPage
  include ActiveModel::Model

  validates :tab_name, presence: true
  validate :assignee_is_user_or_organization

  attr_accessor :assignee, :tab_name, :page
  # attr_accessor :filters, :sort_by, :sort_order

  TASKS_PER_PAGE = 15

  def initialize(args)
    super

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def paged_tasks
    @page ||= 1

    tasks_for_tab.order(:created_at).page(page).per(TASKS_PER_PAGE)
  end

  # sorted_tasks(filtered_tasks(tasks_for_tab)).page(page).per(TASKS_PER_PAGE)
  #
  # # TODO: Enable sorting on fields in different tables.
  # def sorted_tasks(tasks)
  #   # TODO: Validate that we are sorting on a valid field
  #   @sort_by ||= "created_at"
  #   @sort_order ||= "asc" # TODO: Check that sort_order is either asc/desc
  #
  #   tasks.order(sort_by => sort_order)
  # end
  #
  # # TODO: Some filters are on other tables that we will need to join to (appeal docket type)
  # def filtered_tasks(tasks)
  #   filters&.each do |filter_string|
  #     filter = Rack::Utils.parse_query(filter_string)
  #     # TODO: Fail if the filter is not in the correct format
  #     # TODO: Fail if the column we are filtering on is not in some allowed set of columns.
  #     tasks = tasks.where(filter["col"] => filter["val"])
  #   end
  #
  #   tasks
  # end

  def tasks_for_tab
    case tab_name
    when Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME
      tracking_tasks
    when Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME
      unassigned_tasks
    when Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME
      assigned_tasks
    when Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
      recently_completed_tasks
    else
      fail(Caseflow::Error::InvalidTaskTableTab, tab_name: tab_name)
    end
  end

  private

  def tracking_tasks
    TrackVeteranTask.active.where(assigned_to: assignee)
  end

  def unassigned_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def assigned_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).on_hold
  end

  def recently_completed_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).recently_closed
  end

  def assignee_is_user_or_organization
    unless assignee.is_a?(User) || assignee.is_a?(Organization)
      errors.add(:assignee, COPY::TASK_PAGE_INVALID_ASSIGNEE_MESSAGE)
    end
  end
end
