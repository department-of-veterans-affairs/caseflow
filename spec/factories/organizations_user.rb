# frozen_string_literal: true

FactoryBot.define do
  factory :organizations_user do
    association :organization, factory: :organization
    association :user, factory: :user
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end
