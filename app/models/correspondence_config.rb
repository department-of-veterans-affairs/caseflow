# frozen_string_literal: true

class CorrespondenceConfig < QueueConfig
  def to_hash
    {
      table_title: "Temporary table title",
      active_tab: "Temporary active tab name",
      tasks_per_page: 15,
      use_task_pages_api: assignee.use_task_pages_api?,
      tabs: assignee.correspondence_queue_tabs.map { |tab| attach_tasks_to_tab(tab) }
    }
  end

  def attach_tasks_to_tab(tab)
    task_pager = CorrespondenceTaskPager.new(
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
    WorkQueue::CorrespondenceTaskColumnSerializer.new(
      tasks,
      is_collection: true,
      params: { columns: columns }
    ).serializable_hash[:data]
  end
end
