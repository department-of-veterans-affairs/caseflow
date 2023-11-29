# frozen_string_literal: true

class EducationEmoCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_EMO_COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::EDUCATION_EMO_QUEUE_PAGE_COMPLETED_TASKS_DESCRIPTION
  end

  def task_ids_where_parent_has_been_completed
    closed_tasks.select { |task| task.parent.completed? }.pluck(:id)
  end

  def completed_parents
    closed_tasks.map(&:parent).select(&:completed?).pluck(:id)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: completed_parents
    )
  end

  def column_names
    EducationEmo::COLUMN_NAMES
  end
end
