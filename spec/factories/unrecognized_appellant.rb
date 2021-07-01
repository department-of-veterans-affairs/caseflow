# frozen_string_literal: true

FactoryBot.define do
  factory :unrecognized_appellant do
    relationship { "child" }

    association :claimant
    association :unrecognized_party_detail
    association :unrecognized_power_of_attorney, factory: :unrecognized_party_detail

    after(:create) do |unrecognized_appellant, _evaluator|
      unrecognized_appellant.update(current_version_id: unrecognized_appellant.id)
    end
  end
end
