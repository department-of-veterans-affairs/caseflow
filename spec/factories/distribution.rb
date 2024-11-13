# frozen_string_literal: true

FactoryBot.define do
  factory :distribution do
    association :judge, factory: :user

    # This trait requires all case distribution levers to exist in the database
    trait :completed do
      completed_at { Time.zone.now }
      with_stats

      after(:create) do |distribution|
        distribution.update(status: :completed,
                            statistics: { batch_size: distribution.distributed_cases.count,
                                          info: "See related row in distribution_stats for additional stats" })
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

    trait :with_stats do
      after(:create) do |distribution|
        distribution.instance_variable_set(:@appeals, []) if distribution.instance_variable_get(:@appeals).nil?

        distribution.send(:record_distribution_stats, distribution.send(:ama_statistics))
      end
    end
  end
end
