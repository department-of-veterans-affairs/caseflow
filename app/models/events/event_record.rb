# frozen_string_literal: true

class EventRecord < CaseflowRecord
  belongs_to :event
  belongs_to :evented_record, polymorphic: true
  has_many :event_remediation_audits
  store_accessor :info

  enum remediation_status: {
    pending: 0, # the event_record has not yet been processed by the job
    processed: 1, # the event_record was processed by the job without need for remediation
    remediated: 2, # the event_record was processed by the job and successfully remediated
    failed: 3 # the event_record was processed by the job, but the remediation failed
  }

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
