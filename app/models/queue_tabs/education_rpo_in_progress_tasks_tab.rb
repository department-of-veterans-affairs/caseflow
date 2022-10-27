# frozen_string_literal: true

class EducationRpoInProgressTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_RPO_IN_PROGRESS_TASKS_TAB_NAME
  end

  def description
    format(COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_IN_PROGRESS_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    in_progress_tasks
  end

  def column_names
    build_column_names
  end

  private

  def build_column_names
    EducationRpo::COLUMN_NAMES +
      [
        Constants.QUEUE_CONFIG.COLUMNS.DAYS_SINCE_LAST_ACTION.name,
        Constants.QUEUE_CONFIG.COLUMNS.DAYS_SINCE_INTAKE.name
      ].compact
  end
end
