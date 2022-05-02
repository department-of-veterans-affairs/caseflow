# frozen_string_literal: true

class EducationEmoAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_EMO_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::EDUCATION_EMO_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def assigned_parents_of_emo_tasks_ids
    (on_hold_tasks + closed_tasks).map(&:parent).select(&:assigned?).pluck(:id)
  end

  def active_rpo_child_tasks_ids
    on_hold_task_children.select(&:active?).pluck(:id)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: [assigned_parents_of_emo_tasks_ids, active_rpo_child_tasks_ids].flatten
    )
  end

  def column_names
    EducationEmo::COLUMN_NAMES
  end
end
