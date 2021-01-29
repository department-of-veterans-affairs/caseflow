# frozen_string_literal: true

FactoryBot.define do
  factory :bgs_power_of_attorney do
    sequence(:claimant_participant_id)
    sequence(:poa_participant_id)
    representative_name { "POA Name" }
    representative_type { "VSO" }

    trait :with_name_cached do
      transient do
        appeal { nil }
      end
      after(:create) do |bgs_power_of_attorney, evaluator|
        CachedAppeal.create!(
          appeal_id: evaluator.appeal.id,
          appeal_type: evaluator.appeal.class.name,
          power_of_attorney_name: bgs_power_of_attorney.representative_name
        )
      end
    end
  end
end
