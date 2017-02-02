class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EstablishClaim.where(aasm_state: "unprepared").each do |establish_claim|
      establish_claim.prepare! if establish_claim.appeal.decision
    end
  end
end
