class CreateEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    # fetch all full grants
    # These are imported first to enforce the required order of tasks
    if FeatureToggle.enabled?(:dispatch_full_grants)
      AppealRepository.amc_full_grants(outcoded_after: full_grant_outcoded_after).each do |appeal|
        EstablishClaim.find_or_create_by(appeal: appeal)
      end
    end

    # fetch all full grants with a private attorney
    if FeatureToggle.enabled?(:dispatch_full_grants_with_pa)
      AppealRepository.pa_full_grants(outcoded_after: full_grant_outcoded_after).each do |appeal|
        appeal.private_attorney_or_agent = true
        EstablishClaim.find_or_create_by(appeal: appeal)
      end
    end

    # fetch all partial grants
    if FeatureToggle.enabled?(:dispatch_partial_grants_remands)
      AppealRepository.remands_ready_for_claims_establishment.each do |appeal|
        EstablishClaim.find_or_create_by(appeal: appeal)
      end
    end
  end

  # Grab all historical full grants within the last 3 days
  def full_grant_outcoded_after
    VACOLS::Record.relative_vacols_date(3.days)
  end
end
