# frozen_string_literal: true

FactoryBot.define do
  factory :board_grant_effectuation do
    granted_decision_issue do
      create(
        :decision_issue,
        :rating,
        disposition: "allowed",
        decision_review: decision_document.appeal
      )
    end

    decision_document do
      create(:decision_document)
    end

    trait :requires_processing do
      decision_sync_submitted_at { (BoardGrantEffectuation.processing_retry_interval_hours + 1).hours.ago }
      decision_sync_last_submitted_at { (BoardGrantEffectuation.processing_retry_interval_hours + 1).hours.ago }
      decision_sync_processed_at { nil }
    end

    trait :processed do
      decision_sync_processed_at { Time.zone.now }
    end
  end
end
