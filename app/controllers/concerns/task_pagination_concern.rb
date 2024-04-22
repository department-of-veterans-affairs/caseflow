# frozen_string_literal: true

# shared code for controllers that paginate tasks.
# requires methods:
#  * total_items
#  * allowed_params
#

require "stackprof"
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

  private

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

  def json_tasks(tasks)
    puts "-------------------------------------------------- IN JSON TASKS----------------------------------------------"
    start_time1 = Time.zone.now
    StackProf.run(mode: :wall, out: "eager_load_legacy.dump") do
      tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    end
    end_time1 = Time.zone.now
    puts "Eager load took: #{(start_time1 - end_time1) * 1000}"
    params = { user: current_user }

    start_time2 = Time.zone.now
    serialized_tasks = nil
    StackProf.run(mode: :wall, out: "serialize_tasks.dump") do
      serialized_tasks = AmaAndLegacyTaskSerializer.new(
        tasks: tasks, params: params, ama_serializer: WorkQueue::TaskSerializer
      ).call
    end
    end_time2 = Time.zone.now
    puts "Serialization took: #{(start_time2 - end_time2) * 1000}"

    # byebug
    serialized_tasks
  end
end
