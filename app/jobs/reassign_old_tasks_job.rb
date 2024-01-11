# frozen_string_literal: true

class ReassignOldTasksJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :dispatch

  def perform
    DispatchTask.assigned_not_completed.where(type: DispatchTask::REASSIGN_OLD_TASKS).each(&:expire!)
  end
end
