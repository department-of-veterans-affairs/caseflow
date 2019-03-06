# frozen_string_literal: true

class CreateEstablishClaimTasksJob < ApplicationJob
  queue_as :low_priority
  application_attr :dispatch

  def perform
    # fetch all full grants
    # These are imported first to enforce the required order of tasks
    AppealRepository.amc_full_grants(outcoded_after: full_grant_outcoded_after).each do |appeal|
      EstablishClaim.find_or_create_by(appeal: appeal)
    end

    # fetch all partial grants
    AppealRepository.remands_ready_for_claims_establishment.each do |appeal|
      EstablishClaim.find_or_create_by(appeal: appeal)
    end
  end

  # Grab all historical full grants within the last 3 days
  def full_grant_outcoded_after
    VACOLS::Record.relative_vacols_date(3.days)
  end
end
