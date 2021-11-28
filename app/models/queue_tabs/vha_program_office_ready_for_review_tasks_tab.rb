# frozen_string_literal: true

class VhaProgramOfficeReadyForReviewTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_READY_FOR_REVIEW_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.READY_FOR_REVIEW_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_READY_FOR_REVIEW_TASKS_DESCRIPTION, assignee.name)
  end

  def parents_with_child_assess_documentation_task
    assigned_task_children.where(type: AssessDocumentationTask.name)
    .where.not(status: Constants.TASK_STATUSES.cancelled)
    .pluck(:parent_id)
  end

  def tasks
    # byebug
    Task.includes(*task_includes).visible_in_queue_table_view
    .where(id: parents_with_child_assess_documentation_task)
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
