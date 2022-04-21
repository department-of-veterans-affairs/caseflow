# frozen_string_literal: true

class EducationEmoAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::EDUCATION_EMO_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def active_parents_of_emo_tasks_assigned_to_rpos_or_bva
    (on_hold_tasks + closed_tasks).map(&:parent).reject(&:closed?)
  end

  def task_ids_without_newer_siblings
    sibling_task_groups = active_parents_of_emo_tasks_assigned_to_rpos_or_bva.map(&:children)

    sibling_task_groups.map do |children|
      newest_child = children.select { |child| child.assigned_to_id == assignee.id }.max_by(&:id)

      newest_child.id if newest_child.status != Constants.TASK_STATUSES.assigned
    end
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: task_ids_without_newer_siblings
    )
  end

  def column_names
    EducationEmo::COLUMN_NAMES
  end
end
