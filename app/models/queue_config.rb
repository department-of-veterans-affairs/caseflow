# frozen_string_literal: true

class QueueConfig
  include ActiveModel::Model

  attr_accessor :organization

  def initialize(args)
    super

    if !organization&.is_a?(Organization)
      fail(
        Caseflow::Error::MissingRequiredProperty,
        message: "organization property must be an instance of Organization"
      )
    end
  end

  def to_hash_for_user(user)
    {
      table_title: format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name),
      active_tab: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      tasks_per_page: TaskPager::TASKS_PER_PAGE,
      use_task_pages_api: use_task_pages_api?(user),
      tabs: tabs(user).map { |tab| attach_tasks_to_tab(tab, user) }
    }
  end

  private

  def use_task_pages_api?(user)
    FeatureToggle.enabled?(:use_task_pages_api, user: user) && organization.use_task_pages_api?
  end

  def tabs(user)
    queue_tabs = organization.queue_tabs
    use_task_pages_api?(user) ? queue_tabs : queue_tabs.reject { |tab| tab.is_a?(::OnHoldTasksTab) }
  end

  def attach_tasks_to_tab(tab, user)
    task_pager = TaskPager.new(assignee: organization, tab_name: tab.name)

    # Only return tasks in the configuration if we are using it to populate the first page of results.
    # Otherwise avoid the overhead of the additional database requests.
    tasks = use_task_pages_api?(user) ? serialized_tasks_for_user(task_pager.paged_tasks, user) : []

    endpoint = "#{organization.path}/task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"

    tab.to_hash.merge(
      label: tab.label,
      tasks: tasks,
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      task_page_endpoint_base_path: endpoint
    )
  end

  def serialized_tasks_for_user(tasks, user)
    return [] if tasks.empty?

    primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    organization.ama_task_serializer.new(
      primed_tasks,
      is_collection: true,
      params: { user: user }
    ).serializable_hash[:data]
  end
end
