# frozen_string_literal: true

class VhaProgramOfficeOnHoldTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_ON_HOLD_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.ON_HOLD_TASKS_TAB_NAME
  end

  def description
    format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
      Task.includes(*task_includes).visible_in_queue_table_view.on_hold
      .where(assigned_to: VhaProgramOffice.all.map(&:id))
  end

  def column_names
    VhaProgramOffice::COLUMN_NAMES
  end
end
