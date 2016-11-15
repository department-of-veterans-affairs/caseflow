class ReassignOldTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EstablishClaim.assigned_not_completed.each(&:duplicate_and_mark_complete!)
  end
end
