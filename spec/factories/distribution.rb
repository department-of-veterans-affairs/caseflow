# frozen_string_literal: true

FactoryBot.define do
  factory :distribution do
    association :judge, factory: :user

    trait :completed do
      after(:create) do |distribution|
        distribution.update(status: :completed)
      end
    end

    trait :priority do
      priority_push { true }
    end

    trait :this_month do
      completed_at { 5.days.ago }
    end

    trait :last_month do
      completed_at { 35.days.ago }
    end
  end
end
