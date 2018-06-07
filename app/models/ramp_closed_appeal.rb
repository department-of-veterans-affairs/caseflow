class RampClosedAppeal < ApplicationRecord
  class NoReclosingBvaDecidedAppeals < StandardError; end

  belongs_to :ramp_election

  delegate :established_at, to: :ramp_election

  def reclose!
    # If the ramp election was already rolled back, it can't be reclosed, so skip
    return unless ramp_election.established?

    # If the end product was canceled, don't re-close the VACOLS appeal.
    # Instead rollback the RAMP election data from Caseflow
    return ramp_election.rollback! if ramp_election.end_product_canceled?

    fail NoReclosingBvaDecidedAppeals if appeal.decided_by_bva?

    # Need to reopen the appeal first if its not active before we can close it
    if !appeal.active?
      LegacyAppeal.reopen(
        appeals: [appeal],
        user: User.system_user,
        disposition: "RAMP Opt-in",
        safeguards: false
      )
    end

    LegacyAppeal.close(
      appeals: [appeal],
      user: User.system_user,
      closed_on: ramp_election.established_at,
      disposition: "RAMP Opt-in"
    )
  end

  def appeal
    @appeal ||= LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end

  def self.reclose_all!
    appeals_to_reclose = []

    find_in_batches(batch_size: 800) do |batch|
      appeals_to_reclose += AppealRepository.find_ramp_reopened_appeals(batch.map(&:vacols_id))
    end

    appeals_to_reclose = appeals_to_reclose.map do |appeal|
      RampClosedAppeal.find_by(vacols_id: appeal.vacols_id)
    end

    if FeatureToggle.enabled?(:reclose_ramp_appeals_script)
      appeals_to_reclose.each(&:reclose!)
    end
  end
end
