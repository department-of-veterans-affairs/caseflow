# frozen_string_literal: true

FactoryBot.define do
  factory :schedulable_cutoff_date do
    created_at { Time.zone.now }
    cutoff_date { Time.zone.today + 30.days }
    created_by_id { create(:user).id }
  end
end
