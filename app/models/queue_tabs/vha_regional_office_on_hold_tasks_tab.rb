# frozen_string_literal: true

class VhaRegionalOfficeOnHoldTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_ON_HOLD_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.VHA_PO_ON_HOLD_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION, assignee.name)
  end

  def po_on_hold_tasks
    on_hold_tasks.where(type: :AssessDocumentationTask)
  end

  def parents_with_child_assess_documentation_task_ids
    on_hold_task_children.where(type: :AssessDocumentationTask)
      .pluck(:parent_id).uniq
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: (po_on_hold_tasks.map(&:id) + visible_child_task_ids) - parents_with_child_assess_documentation_task_ids
    )
  end

  def column_names
    VhaRegionalOffice::COLUMN_NAMES
  end
end
