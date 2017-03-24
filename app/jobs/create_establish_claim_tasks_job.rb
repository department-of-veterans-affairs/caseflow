class CreateEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    # fetch all full grants
    # These are imported first to enforce the required order of tasks
    if FeatureToggle.enabled?(:dispatch_full_grants)
      AppealRepository.amc_full_grants(outcoded_after: full_grant_outcoded_after).each do |appeal|
        add_establish_claim_data(appeal)
      end
    end

    # fetch all partial grants
    if FeatureToggle.enabled?(:dispatch_partial_grants_remands)
      AppealRepository.remands_ready_for_claims_establishment.each do |appeal|
        add_establish_claim_data(appeal)
      end
    end
  end

  # Grab all historical full grants within the last 3 days
  def full_grant_outcoded_after
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

  # Creates a new EstablishClaim task and it's related meta data information
  # using the infromation from appeal.
  def add_establish_claim_data(appeal)
    EstablishClaim
      .find_or_create_by(appeal: appeal) do |establish_claim_task|
      # create a new claim establishment only if a new establish
      # claim task is created.
      ClaimEstablishment.create(
        decision_date: appeal.outcoding_date,
        task: establish_claim_task,
        appeal: appeal
      )
    end
  end
end
