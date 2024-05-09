# frozen_string_literal: true

class EventRecord < CaseflowRecord
  belongs_to :event
  belongs_to :evented_record, polymorphic: true

  validate :valid_evented_record

  def valid_evented_record
    unless %w[
      Intake
      ClaimReview
      HigherLevelReview
      SupplementalClaim
      EndProductEstablishment
      Claimant
      Veteran
      Person
      RequestIssue
      LegacyIssue
      LegacyIssueOptin
      User
    ].include?(evented_record_type)

      errors.add(:evented_record_type, "is not a valid evented record")
    end
  end
end
