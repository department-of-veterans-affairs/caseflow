# frozen_string_literal: true

# A DTO (data transfer object) class that stipulates all queue table attributes and tasks.
# This configuration and sets of tasks are used on the frontend to build and display an
# organization's or user's queue.
class QueueConfig
  include ActiveModel::Model

  attr_accessor :assignee

  def initialize(args)
    super

    if !assignee&.is_a?(Organization) && !assignee&.is_a?(User)
      fail(
        Caseflow::Error::MissingRequiredProperty,
        message: "assignee property must be an instance of Organization or User"
      )
    end
  end

  def to_hash
    table_title = COPY::USER_QUEUE_PAGE_TABLE_TITLE
    {
      table_title: assignee_is_org? ? format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, assignee.name) : table_title,
      active_tab: assignee.class.default_active_tab,
      tasks_per_page: TaskPager::TASKS_PER_PAGE,
      use_task_pages_api: assignee.use_task_pages_api?,
      tabs: assignee.queue_tabs.map { |tab| attach_tasks_to_tab(tab) }
    }
  end

  private

  def assignee_is_org?
    assignee.is_a?(Organization)
  end

  def attach_tasks_to_tab(tab)
    task_pager = TaskPager.new(
      assignee: assignee,
      tab_name: tab.name,
      sort_by: tab.default_sorting_column.name,
      sort_order: tab.default_sorting_direction
    )
    endpoint = "task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"

    tab.to_hash.merge(
      tasks: serialized_tasks_for_columns(task_pager.paged_tasks, tab.column_names),
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      task_page_endpoint_base_path: "#{assignee_is_org? ? "#{assignee.path}/" : "users/#{assignee.id}/"}#{endpoint}"
    )
  end

  def serialized_tasks_for_columns(tasks, columns)
    return [] if tasks.empty?

    primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    WorkQueue::TaskColumnSerializer.new(
      primed_tasks,
      is_collection: true,
      params: { columns: columns }
    ).serializable_hash[:data]
  end
end
