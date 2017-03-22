class CreateEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  DECSION_TYPES = {
    "Full Grant" => :full_grant,
    "Partial Grant" => :partial_grant,
    "Remand" => :remand
  }.freeze

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

  # add_establish_claim_meta
  #
  # Creates a new EstablishClaim task and it's related meta data information
  # using the infromation from appeal.
  def add_establish_claim_data(appeal)
    EstablishClaim
      .find_or_create_by(appeal: appeal) do |establish_claim_task|
      # create a new claim establishment only if a new establish
      # claim task is created.
      ClaimEstablishment.create(
        decision_type: CreateEstablishClaimTasksJob.get_decision_type(appeal),
        decision_date: appeal.outcoding_date,
        task: establish_claim_task
      )
    end
  end

  # get_decision_type
  #
  # returns the type of a decision based on appeal data
  # If a type is not matched, it returns nil
  def self.get_decision_type(appeal)
    DECSION_TYPES[appeal.decision_type]
  end
end
