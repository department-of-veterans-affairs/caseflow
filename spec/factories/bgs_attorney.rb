# frozen_string_literal: true

types = [
  "POA State Organization",
  "POA National Organization",
  "POA Attorney",
  "POA Agent",
  "POA Local/Regional Organization"
]

FactoryBot.define do
  factory :bgs_attorney do
    last_synced_at { 12.hours.ago }
    participant_id { generate :participant_id }
    name { Faker::Name.name }
    record_type { types.sample }
  end
end
