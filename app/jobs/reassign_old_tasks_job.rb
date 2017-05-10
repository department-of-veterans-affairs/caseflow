class ReassignOldTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    Task.assigned_not_completed.where(type: Task::REASSIGN_OLD_TASKS).each(&:expire!)
  end
end
