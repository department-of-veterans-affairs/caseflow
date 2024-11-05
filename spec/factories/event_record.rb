# frozen_string_literal: true

FactoryBot.define do
  factory :person_event_record do
    sequence(:id) { |n| n }
    event_record_id { 1 }
    event_record_type { "Person" }
    created_at { DateTime.now }
    updated_at { DateTime.now }
    info { {} }
  end
end
