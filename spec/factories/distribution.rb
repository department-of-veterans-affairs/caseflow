# frozen_string_literal: true

FactoryBot.define do
  factory :distribution do
    association :judge, factory: :user

    trait :completed do
      completed_at { Time.zone.now }
      after(:create) do |distribution|
        distribution.update(status: :completed, statistics: { batch_size: distribution.distributed_cases.count })
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
