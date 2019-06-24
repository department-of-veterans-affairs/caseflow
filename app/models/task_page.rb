# frozen_string_literal: true

class TaskPage
  include ActiveModel::Model

  TASKS_PER_PAGE = 15

  attr_accessor :assignee, :tab_name, :filters, :sort_by, :sort_order, :page

  # /organizations/{org.url}/tasks?
  #   tab=on_hold&
  #   sort_by=case_details_link&
  #   order=desc&
  #   filter[]=col%3Ddocket_type%26val%3Dlegacy&
  #   filter[]=col%3Dtask_action%26val%3Dtranslation&
  #   page=3
  #
  # params = <ActionController::Parameters {
  #   "tab"=>"on_hold",
  #   "sort_by"=>"case_details_link",
  #   "order"=>"desc",
  #   "filter"=>["col=docket_type&val=legacy", "col=task_action&val=translation"],
  #   "page"=>"3"
  # }>
  #
  #   TaskPage.new(
  #     assignee: organization,
  #     tab_name: params[:tab],
  #     filters: params[:filter],
  #     sort_order: params[:order],
  #     sort_by: params[:sort_by],
  #     page: params[:page]
  #   ).paged_tasks
  #
  #
  #   org = Colocated.singleton
  #   tasks = TaskPage.new(
  #     assignee: org,
  #     tab_name: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
  #     filters: ["col=task_action&val=extension"],
  #   ).paged_tasks

  # TODO: Can I make this a little more rails-y?
  def paged_tasks
    @page ||= 1

    sorted_tasks(filtered_tasks(tasks_for_tab)).page(page).per(TASKS_PER_PAGE)
  end

  # TODO: Enable sorting on fields in different tables.
  def sorted_tasks(tasks)
    # TODO: Validate that we are sorting on a valid field
    @sort_by ||= "created_at"
    @sort_order ||= "asc" # Check that sort_order is either asc/desc

    tasks.order(sort_by => sort_order)
  end

  # TODO: Some filters are on other tables that we will need to join to (appeal docket type)
  def filtered_tasks(tasks)
    filters&.each do |filter_string|
      filter = Rack::Utils.parse_query(filter_string)
      # TODO: Fail if the filter is not in the correct format
      # TODO: Fail if the column we are filtering on is not in some allowed set of columns.
      tasks = tasks.where(filter["col"] => filter["val"])
    end

    tasks
  end

  # TODO: Does this delay the actual execution of these functions until we need their results?
  # Perhaps we could use yield or to_sql
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
end
