# frozen_string_literal: true

class VhaRegionalOfficeAssignedTasksTab < QueueTab
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

  def parent_ids_with_completed_child_assess_documentation_task
    assigned_task_children.where(type: :AssessDocumentationTask)
      .completed
      .pluck(:parent_id).uniq
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: assigned_tasks.map(&:id) - parent_ids_with_completed_child_assess_documentation_task
    )
  end

  def column_names
    VhaRegionalOffice::COLUMN_NAMES
  end
end
