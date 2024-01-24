# frozen_string_literal: true

class CorrespondenceTaskPager < TaskPager
  def paged_tasks
    @paged_tasks ||= begin
      tasks = sorted_tasks(filtered_tasks)
      pagination_enabled ? tasks.page(page).per(TASKS_PER_PAGE) : tasks
    end
  end
end
