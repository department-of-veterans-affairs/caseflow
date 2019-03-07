# frozen_string_literal: true

class ReassignOldTasksJob < ApplicationJob
  queue_as :low_priority
  application_attr :dispatch

  def perform
    Dispatch::Task.assigned_not_completed.where(type: Dispatch::Task::REASSIGN_OLD_TASKS).each(&:expire!)
  end
end
