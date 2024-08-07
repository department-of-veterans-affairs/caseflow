# frozen_string_literal: true

class CorrespondenceTaskPager < TaskPager
  def filtered_tasks
    CorrespondenceTaskFilter.new(filter_params: filters, tasks: tasks_for_tab).filtered_tasks
  end

  def queue_tab
    @queue_tab ||= CorrespondenceQueueTab.from_name(tab_name).new(assignee: assignee)
  end

  def paged_tasks
    @paged_tasks ||= begin
      tasks = sorted_tasks(filtered_tasks)
      pagination_enabled ? tasks.page(page).per(TASKS_PER_PAGE) : tasks
    end
  end
end
