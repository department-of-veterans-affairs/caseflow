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
end
