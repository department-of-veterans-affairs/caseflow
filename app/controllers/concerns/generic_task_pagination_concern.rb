# frozen_string_literal: true

# Primarily used to provides method to the DecisionReviewsController
# so that it can paginate tasks for business lines' decision review queues.
#
# However, this concern may be used in any controller where tasks are needing
# to be paginated, but TaskPager is not desired to be used.
#
# Tasks to be paginated must implement a 'serialize_task' method that returns
# a serialized version of itself.
module GenericTaskPaginationConcern
  extend ActiveSupport::Concern

  DEFAULT_TASKS_PER_PAGE = 15

  def pagination_json(task_list)
    task_count = task_list.size
    total_pages = (task_count / DEFAULT_TASKS_PER_PAGE.to_f).ceil

    {
      tasks: {
        data: paginate_tasks(task_list).map(&:serialize_task)
      },
      tasks_per_page: DEFAULT_TASKS_PER_PAGE,
      task_page_count: total_pages,
      total_task_count: task_count
    }
  end

  def paginate_tasks(task_list)
    tasks = task_list.is_a?(Array) ? Kaminari.paginate_array(task_list) : task_list

    tasks
      .page(allowed_params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym] || 1)
      .per(DEFAULT_TASKS_PER_PAGE)
  end

  def pagination_query_params(sort_by_column = allowed_params[Constants.QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM.to_sym])
    {
      sort_order: allowed_params[Constants.QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM.to_sym],
      sort_by: sort_by_column,
      filters: allowed_params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym],
      search_query: allowed_params[Constants.QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM.to_sym]
    }.compact
  end
end
