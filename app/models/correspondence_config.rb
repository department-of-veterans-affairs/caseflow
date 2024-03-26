# frozen_string_literal: true

# :reek:RepeatedConditional

class CorrespondenceConfig < QueueConfig
  def to_hash
    {
      table_title: table_title,
      active_tab: default_active_tab,
      tasks_per_page: 15,
      use_task_pages_api: true,
      tabs: assignee.correspondence_queue_tabs.map { |tab| attach_tasks_to_tab(tab) }
    }
  end

  private

  # :reek:FeatureEnvy
  def attach_tasks_to_tab(tab)
    task_pager = CorrespondenceTaskPager.new(
      assignee: assignee,
      tab_name: tab.name,
      sort_by: tab.default_sorting_column.name,
      sort_order: tab.default_sorting_direction
    )
    endpoint = "task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"
    base_path = if assignee_is_org?
                  "organizations/#{assignee.id}/#{endpoint}"
                else
                  "correspondence/users/#{assignee.id}/#{endpoint}"
                end

    tab.to_hash.merge(
      tasks: serialized_tasks_for_columns(task_pager.paged_tasks, tab.column_names),
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      task_page_endpoint_base_path: base_path
    )
  end

  def serialized_tasks_for_columns(tasks, columns)
    WorkQueue::CorrespondenceTaskColumnSerializer.new(
      tasks,
      is_collection: true,
      params: { columns: columns }
    ).serializable_hash[:data]
  end

  def table_title
    if assignee_is_org?
      Constants.QUEUE_CONFIG.CORRESPONDENCE_ORG_TABLE_TITLE
    else
      Constants.QUEUE_CONFIG.CORRESPONDENCE_USER_TABLE_TITLE
    end
  end

  def default_active_tab
    if assignee_is_org?
      Constants.QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_TAB_NAME
    else
      Constants.QUEUE_CONFIG.CORRESPONDENCE_ASSIGNED_TASKS_TAB_NAME
    end
  end

  def default_sorting_column
    Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name
  end
end
