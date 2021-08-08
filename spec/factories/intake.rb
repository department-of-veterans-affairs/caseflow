# frozen_string_literal: true

FactoryBot.define do
  factory :intake do
    veteran_file_number { create(:veteran).file_number }
    detail { create(:higher_level_review) }
    type { detail.class.name + "Intake" }
    started_at { Time.zone.now }
    association :user

    trait :completed do
      completed_at { Time.zone.now }
      completion_status { "success" }
    end
  end
end
