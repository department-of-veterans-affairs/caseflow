# frozen_string_literal: true

FactoryBot.define do
  factory :event_record do
    sequence(:id) { |n| n }
    event_record_id { 1 }
    event_record_type { "" }
    created_at { DateTime.now }
    updated_at { DateTime.now }
    info { {} }

    trait :person_event_record do
      event_record_type { "Person" }
    end

    trait :veteran_event_record do
      event_record_type { "Veteran" }
    end
  end
end
