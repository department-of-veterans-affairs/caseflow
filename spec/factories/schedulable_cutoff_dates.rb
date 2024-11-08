# frozen_string_literal: true

FactoryBot.define do
  factory :schedulable_cutoff_date do
    id { "" }
    created_at { "2024-11-07 13:55:59" }
    cutoff_date { "2024-11-07" }
    created_by_id { "1" }
  end
end
