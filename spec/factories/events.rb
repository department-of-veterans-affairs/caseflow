# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence(:id) { |n| n }
    reference_id { 2 }
    type { "DecisionReviewCreatedEvent" }
    created_at { DateTime.now }
    updated_at { DateTime.now }
    completed_at { nil }
    error { nil }
    info { {} }
  end
end
