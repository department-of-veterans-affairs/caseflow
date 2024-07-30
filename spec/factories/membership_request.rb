# frozen_string_literal: true

FactoryBot.define do
  factory :membership_request do
    association :requestor, factory: :user
    association :organization, factory: :organization

    trait :completed do
      association :decider, factory: :user

      status { "approved" }
      decided_at { Faker::Date.backward }
    end
  end
end
