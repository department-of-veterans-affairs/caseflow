# frozen_string_literal: true

class EventRemediationAudit < CaseflowRecord
  belongs_to :event_record
  has_one :remediated_record
  store_accessor :info

  validate :valid_remediated_record

  def valid_remediated_record
    unless %w[
      Appeal
      AvailableHearingLocations
      BgsPowerOfAttorney
      Document
      EndProductEstablishment
      Form8
      HigherLevelReview
      Intake
      LegacyAppeal
      RampElection
      RampRefiling
      SupplementalClaim
    ].include?(remediated_record_type)

      errors.add(:remediated_record_type, "is not a valid remediated record")
    end
  end
end
