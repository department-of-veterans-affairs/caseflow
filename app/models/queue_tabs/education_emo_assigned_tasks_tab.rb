# frozen_string_literal: true

class EducationEmoAssignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.EDUCATION_ASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def task_ids_where_parent_has_been_closed
    closed_tasks.select { |task| task.parent.closed? }.pluck(:id)
  end

  def tasks_emo_sent_elsewhere
    on_hold_tasks.map(&:id) + closed_tasks.map(&:id)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: (tasks_emo_sent_elsewhere - task_ids_where_parent_has_been_closed)
    )
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
    ].compact
  end
end
