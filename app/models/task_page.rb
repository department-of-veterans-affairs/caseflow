# frozen_string_literal: true

class TaskPage
  include ActiveModel::Model

  attr_accessor :assignee

  def tasks_for_tab(tab_name)
    TASK_FUNCTION_FOR_TAB_NAME[tab_name]
  end

  private

  # TODO: Does this call the ..._tasks functions? Or does it return a reference to them?
  #   we want the latter.
  TASK_FUNCTION_FOR_TAB_NAME = {
    Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME => tracking_tasks,
    Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME => unassigned_tasks,
    Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME => assigned_tasks,
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME => recently_completed_tasks
  }.freeze

  def tracking_tasks
    TrackVeteranTask.active.where(assigned_to: assignee)
  end

  def unassigned_tasks
    Task.active.where(assigned_to: assignee).reject(&:hide_from_queue_table_view)
  end

  def assigned_tasks
    Task.on_hold.where(assigned_to: assignee).reject(&:hide_from_queue_table_view)
  end

  def recently_completed_tasks
    Task.recently_closed.where(assigned_to: assignee).reject(&:hide_from_queue_table_view)
  end
end
