# frozen_string_literal: true

class EducationRpoCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  :allow_bulk_assign

  def label
    COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_UNASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  # In each case, if the EMO task is assigned, then it should meet each use case for the unassigned tab
  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  # Column names defined in each tab in education predocket due to different columns needed
  # Actual names found in QUEUE_CONFIG.json file
  def column_names
    EduRegionalProcessingOffice::COLUMN_NAMES
  end
end
