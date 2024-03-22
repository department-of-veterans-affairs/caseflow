# frozen_string_literal: true

FactoryBot.define do
  factory :unrecognized_appellant do
    relationship { "child" }

    association :claimant
    association :unrecognized_party_detail
    association :unrecognized_power_of_attorney, factory: :unrecognized_party_detail
    association :created_by, factory: :user

    after(:create) do |unrecognized_appellant, _evaluator|
      unrecognized_appellant.update(current_version_id: unrecognized_appellant.id)
    end

    trait :with_not_listed_power_of_attorney do
      after(:create) do |unrecognized_appellant, _evaluator|
        unrecognized_appellant.update(
          not_listed_power_of_attorney: create(:not_listed_power_of_attorney),
          unrecognized_party_detail: nil,
          unrecognized_power_of_attorney: nil
        )
      end
    end
  end
end
