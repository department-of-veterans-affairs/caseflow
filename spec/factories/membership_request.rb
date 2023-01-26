# frozen_string_literal: true

FactoryBot.define do
  factory :membership_request do
    association :requestor, factory: :user
    association :organization, factory: :organization

    requested_by_id { Faker::Number.number(digits: 4) }
    decided_by_id { Faker::Number.number(digits: 4) }
    decided_at { Faker::Date.backward }
  end
end
