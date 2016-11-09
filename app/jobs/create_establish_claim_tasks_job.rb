class CreateEstablishClaimTasksJob # < ActiveJob::Base
  def perform(full_grant_decided_after)
    # fetch all partial grants
    AppealRepository.remands_ready_for_claims_establishment.each do |appeal|
      CreateEndProduct.find_or_create_by(appeal: appeal)
    end

    # fetch all full grants
    AppealRepository.amc_full_grants(decided_after: full_grant_decided_after).each do |appeal|
      CreateEndProduct.find_or_create_by(appeal: appeal)
    end
  end
end
