# frozen_string_literal: true

class DecisionReviewCreatedEvent < ApplicationRecord
  store_accessor :info, :errored_claim_id

  # Scope for events with non-null errored_claim_id
  scope :with_errored_claim_id, -> { where.not("info -> 'errored_claim_id' IS NULL") }
end
