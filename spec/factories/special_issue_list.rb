# frozen_string_literal: true

FactoryBot.define do
  factory :special_issue_list do
    military_sexual_trauma { true }
    appeal_type { "Appeal" }

    trait :ama do
      appeal
    end

    trait :legacy do
      appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    end
  end
end
