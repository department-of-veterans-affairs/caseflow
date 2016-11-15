class ReassignOldTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EstablishClaim.assigned_not_completed.each do | task |
      task.duplicate_and_mark_complete! 
    end
  end

end