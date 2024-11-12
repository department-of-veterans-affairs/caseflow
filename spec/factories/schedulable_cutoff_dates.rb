# frozen_string_literal: true

FactoryBot.define do
  factory :schedulable_cutoff_date do
    id { 1 }
    created_at { Time.zone.now }
    cutoff_date { Time.zone.today + 30.days }
    created_by_id do
      create(:appeal)
      appeal.id
    end
  end
end
