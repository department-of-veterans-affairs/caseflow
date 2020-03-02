# frozen_string_literal: true

# Used to perform and record instances where we need to rollback a RampElection
# Currently this is only used to perform rollbacks manually from the command line
#
# Saving the rollback will perform all validations and actions required.
# Example:
#
# RollbackRampElection.create!(ramp_election: ramp_election, user: user, reason: "A good reason")
class RampElectionRollback < CaseflowRecord
  belongs_to :user
  belongs_to :ramp_election

  validates :user, :ramp_election, :reason, presence: true
  validate  :validate_canceled_end_product

  before_create :reopen_vacols_appeals!, :rollback_ramp_election

  private

  def rollback_ramp_election
    ramp_election.rollback!
  end

  def reopen_vacols_appeals!
    LegacyAppeal.reopen(appeals: appeals_to_reopen, user: user, disposition: "RAMP Opt-in")

    self.reopened_vacols_ids = appeals_to_reopen.map(&:vacols_id)
  end

  def appeals_to_reopen
    ramp_election_closed_appeals.reject(&:active?)
  end

  def ramp_election_closed_appeals
    ramp_election_vacols_ids.map do |vacols_id|
      LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
    end
  end

  def ramp_election_vacols_ids
    @ramp_election_vacols_ids ||= ramp_election.ramp_closed_appeals.map(&:vacols_id)
  end

  # We currently don't cancel the associated ramp election EP, we
  # require that it was canceled manually beforehand
  def validate_canceled_end_product
    establishment = EndProductEstablishment.find_by(source: ramp_election)
    unless establishment&.status_canceled?
      errors.add(:ramp_election, "end_product_not_canceled")
    end
  end
end
