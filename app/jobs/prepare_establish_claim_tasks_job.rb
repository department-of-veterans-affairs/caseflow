class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EstablishClaim.unprepared.each do |establish_claim|
      establish_claim.prepare! if establish_claim.appeal.decisions.count > 0
    end
  end
end
