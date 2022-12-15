# frozen_string_literal: true

# Provides methods to the DecisionReviewsController so that it can paginate
# tasks for business lines' decision review queues.
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
        data: apply_task_serializer(paginate_tasks(task_list))
      },
      tasks_per_page: DEFAULT_TASKS_PER_PAGE,
      task_page_count: total_pages,
      total_task_count: task_count
    }
  end

  def paginate_tasks(task_list)
    tasks = task_list.is_a?(Array) ? Kaminari.paginate_array(task_list) : task_list

    tasks.page(allowed_params[:page] || 1).per(DEFAULT_TASKS_PER_PAGE)
  end

  def apply_task_serializer(tasks)
    tasks.map(&:serialize_task)
  end
end
