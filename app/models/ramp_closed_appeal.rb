# frozen_string_literal: true

class RampClosedAppeal < CaseflowRecord
  class NoReclosingBvaDecidedAppeals < StandardError; end

  belongs_to :ramp_election

  attr_writer :user

  delegate :established_at, to: :ramp_election

  # If an appeal was only partially closed (because it contained some ineligible issues)
  # then we record the issue ids that were closed.
  def partial?
    !!partial_closure_issue_sequence_ids
  end

  def close!
    if partial?
      partial_closure_issue_sequence_ids.each do |vacols_sequence_id|
        Issue.update_in_vacols!(
          vacols_id: vacols_id,
          vacols_sequence_id: vacols_sequence_id,
          issue_attrs: {
            disposition: "P",
            disposition_date: Time.zone.today
          }
        )
      end
    else
      LegacyAppeal.close(
        appeals: [appeal],
        user: user,
        closed_on: closed_on || ramp_election.established_at,
        disposition: "RAMP Opt-in"
      )
    end
  end

  def reclose!
    # If the ramp election was already rolled back, it can't be reclosed, so skip
    return unless ramp_election.established?

    # If the end product was canceled, don't re-close the VACOLS appeal.
    # Instead rollback the RAMP election data from Caseflow
    return ramp_election.rollback! if ramp_election.end_product_establishment.status_cancelled?

    fail NoReclosingBvaDecidedAppeals if appeal.decided_by_bva?

    # Need to reopen the appeal first if its not active before we can close it
    if !appeal.active?
      LegacyAppeal.reopen(
        appeals: [appeal],
        user: user,
        disposition: "RAMP Opt-in",
        safeguards: false
      )

      # reload the appeal now that it's active
      @appeal = nil
    end

    close!
  end

  def appeal
    @appeal ||= LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end

  private

  def user
    @user || User.system_user
  end

  class << self
    def fully_closed
      where(partial_closure_issue_sequence_ids: nil)
    end

    def partial
      where.not(partial_closure_issue_sequence_ids: nil)
    end

    def appeals_to_reclose
      ramp_reopened_appeals = []

      fully_closed.find_in_batches(batch_size: 800) do |batch|
        ramp_reopened_appeals += AppealRepository.find_ramp_reopened_appeals(batch.map(&:vacols_id))
      end

      ramp_reopened_appeals.map do |legacy_appeal|
        find_by(vacols_id: legacy_appeal.vacols_id)
      end
    end
  end
end
