# frozen_string_literal: true

class EventRemediationAudit < CaseflowRecord
  belongs_to :event_record
  belongs_to :remediated_record, polymorphic: true
  store_accessor :info

  validate :valid_remediated_record
  validate :valid_remediation_type

  # rubocop: disable Metrics/MethodLength
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
      Claimant
      DecisionIssue
      RequestIssue
      Notification
      VeteranClaimant
      DependentClaimant
      AttorneyClaimant
    ].include?(remediated_record_type)

      errors.add(:remediated_record_type, "is not a valid remediated record")
    end
  end

  def valid_remediation_type
    valid_types = [
      "VeteranRecordRemediationService",
      "DuplicatePersonRemediationService"
    ]

    unless valid_types.include?(info["remediation_type"])
      errors.add(:info, "remediation_type is not valid")
    end
  end
end
