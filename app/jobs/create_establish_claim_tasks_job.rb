class CreateEstablishClaimTasksJob < ActiveJob::Base
  def perform
    # fetch all partial grants
    AppealRepository.remands_ready_for_claims_establishment.each do |appeal|
      EstablishClaim.find_or_create_by(appeal: appeal)
    end

    # fetch all full grants
    AppealRepository.amc_full_grants(decided_after: full_grant_decided_after).each do |appeal|
      EstablishClaim.find_or_create_by(appeal: appeal)
    end
  end

  # Grab all historical full grants within the last 3 days
  def full_grant_decided_after
    time = Time.now.utc
    Time.utc(
      time.year,
      time.month,
      time.day - 2
    )
  end
end
