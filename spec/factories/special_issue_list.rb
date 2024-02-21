# frozen_string_literal: true

FactoryBot.define do
  factory :special_issue_list do
    trait :ama do
      appeal
    end

    trait :legacy do
      appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    end
  end
end
