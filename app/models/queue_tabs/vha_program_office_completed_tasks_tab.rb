# frozen_string_literal: true

class VhaProgramOfficeCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  # def task_includes
  #     # Customer version of this method
  # end

  def tasks
  Task.includes(*task_includes).visible_in_queue_table_view
  .where(assigned_to: VhaProgramOffice.all.map(&:id))
  .closed
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
