# frozen_string_literal: true

class VhaProgramOfficeCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.VHA_PO_COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
  end

  def parent_ids_with_cancelled_assess_documentation_task
    Task.where(type: :AssessDocumentationTask, assigned_to: assignee)
      .cancelled
      .pluck(:id).uniq
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: closed_tasks.map(&:id) - parent_ids_with_cancelled_assess_documentation_task
    )
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
