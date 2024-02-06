# frozen_string_literal: true

class EventRecord < CaseflowRecord
  belongs_to :event
  belongs_to :backfill_record, polymorphic: true

  validate :valid_backfill_record

  %w[403 404].include?(params[:status_code]) ? params[:status_code] : "500"

  def valid_backfill_record
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
    ].include?(backfill_record_type)

      errors.add(:backfill_record_type, "is not a valid backfill record")
    end
  end
end
