# frozen_string_literal: true

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
      tabs: tabs.map { |tab| attach_tasks_to_tab(tab) }
    }
  end

  private

  def assignee_is_org?
    assignee.is_a?(Organization)
  end

  def tabs
    queue_tabs = assignee.queue_tabs

    return queue_tabs unless !assignee.use_task_pages_api? && assignee_is_org?

    queue_tabs.reject { |tab| tab.is_a?(::OrganizationOnHoldTasksTab) }
  end

  def attach_tasks_to_tab(tab)
    task_pager = TaskPager.new(assignee: assignee, tab_name: tab.name)

    # Only return tasks in the configuration if we are using it to populate the first page of results.
    # Otherwise avoid the overhead of the additional database requests.
    tasks = assignee.use_task_pages_api? ? serialized_tasks_for_columns(task_pager.paged_tasks, tab.column_names) : []

    endpoint = "task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"

    tab.to_hash.merge(
      tasks: tasks,
      # TODO: Change task_page_count to something like: (tab.tasks.count / TaskPager::TASKS_PER_PAGE.to_f).ceil
      # This allows us to only instantiate TaskPager if we are using the task pages API.
      task_page_count: task_pager.task_page_count,
      total_task_count: tab.tasks.count,
      task_page_endpoint_base_path: "#{assignee_is_org? ? "#{assignee.path}/" : ''}#{endpoint}"
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
