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
end
