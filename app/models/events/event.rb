# frozen_string_literal: true

# This class is the parent class for different events that Caseflow receives from appeals-consumer
class Event < CaseflowRecord
  has_many :event_records
  store_accessor :info, :errored_claim_id

  scope :with_errored_claim_id, -> { where.not("info -> 'errored_claim_id' IS NULL") }

  def completed?
    completed_at?
  end

  def self.find_errors_by_claim_id(claim_id)
    with_errored_claim_id
      .where("info ->> 'errored_claim_id' = ?", claim_id)
      .pluck(:error)
  end

  # Check if there's already a CF Event that references that Appeals-Consumer EventID and
  # was successfully completed
  def self.exists_and_is_completed?(consumer_event_id)
    where(reference_id: consumer_event_id).where.not(completed_at: nil).exists?
  end
end
