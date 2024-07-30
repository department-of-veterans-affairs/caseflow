# frozen_string_literal: true

FactoryBot.define do
  factory :decision_document do
    appeal
    sequence(:citation_number) { |n| "A181#{(n % 100_000).to_s.rjust(5, '0')}" }
    decision_date { Time.zone.today }
    redacted_document_location { "C://Windows/User/BOBLAW/Documents/Decision.docx" }

    trait :requires_processing do
      submitted_at { (DecisionDocument.processing_retry_interval_hours + 1).hours.ago }
      last_submitted_at { (DecisionDocument.processing_retry_interval_hours + 1).hours.ago }
      processed_at { nil }
    end

    trait :processed do
      processed_at { Time.zone.now }
    end

    trait :ama do
      appeal
    end

    trait :legacy do
      appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    end
  end
end
