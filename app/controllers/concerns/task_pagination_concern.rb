# frozen_string_literal: true

# shared code for controllers that paginate tasks.
# requires methods:
#  * total_items
#  * allowed_params
#
module TaskPaginationConcern
  extend ActiveSupport::Concern

  def pagination_json
    {
      tasks: json_tasks(task_pager.paged_tasks),
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      tasks_per_page: TaskPager::TASKS_PER_PAGE
    }
  end

  def correspondence_pagination_json
    {
      tasks: correspondence_json_tasks(correspondence_task_pager.paged_tasks),
      task_page_count: correspondence_task_pager.task_page_count,
      total_task_count: correspondence_task_pager.total_task_count,
      tasks_per_page: CorrespondenceTaskPager::TASKS_PER_PAGE
    }
  end

  private

  def correspondence_task_pager
    @correspondence_task_pager ||= CorrespondenceTaskPager.new(
      assignee: assignee,
      tab_name: params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym],
      page: params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym],
      sort_order: params[Constants.QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM.to_sym],
      sort_by: params[Constants.QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM.to_sym],
      filters: params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym]
    )
  end

  def task_pager
    @task_pager ||= TaskPager.new(
      assignee: assignee,
      tab_name: params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym],
      page: params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym],
      sort_order: params[Constants.QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM.to_sym],
      sort_by: params[Constants.QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM.to_sym],
      filters: params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym]
    )
  end

  def correspondence_json_tasks(tasks)
    tab = CorrespondenceQueueTab.from_name(params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym])

    { data: WorkQueue::CorrespondenceTaskColumnSerializer.new(
      tasks,
      is_collection: true,
      params: { columns: tab.column_names }
    ).serializable_hash[:data] }
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: WorkQueue::TaskSerializer
    ).call
  end
end
