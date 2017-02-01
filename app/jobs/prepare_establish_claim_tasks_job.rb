class PrepareEstablishClaimTasksJob < ActiveJob::Base
  def perform
    EstablishClaim.where(aasm_state: "unprepared").each do |establish_claim|
      establish_claim.prepare! if establish_claim.appeal.documents
    end
  end
end
