class CreateEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

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
    Time.zone = "Eastern Time (US & Canada)"
    current_time = Time.zone.now

    # Round off hours, minutes, and seconds
    rounded_current_time = Time.zone.local(
      current_time.year,
      current_time.month,
      current_time.day
    )

    rounded_current_time - 3.days
  end
end
