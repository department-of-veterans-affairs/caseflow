# frozen_string_literal: true

class VhaProgramOfficeAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.VHA_PO_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def parents_with_child_assess_documentation_task
    assigned_task_children.where(type: AssessDocumentationTask.name)
      .where.not(status: Constants.TASK_STATUSES.completed)
      .pluck(:parent_id)
  end

  def no_children_tasks
    assigned_task_children.where(type: AssessDocumentationTask.name)
      .where(assigned_to_id: assignee.id)
      .pluck(:parent_id)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: [no_children_tasks, parents_with_child_assess_documentation_task].flatten
    )
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
