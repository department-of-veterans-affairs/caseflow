# frozen_string_literal: true

FactoryBot.define do
  factory :appeal_state do
    association :appeal
    created_at { Time.zone.now - 5.hours }
    created_by_id { 1 }
    updated_at { Time.zone.now }
    updated_by_id { 1 }
  end
end
