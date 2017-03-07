class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EstablishClaim.unprepared.each(&:prepare_with_decision!)
  end
end
