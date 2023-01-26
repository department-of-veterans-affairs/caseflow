# frozen_string_literal: true

FactoryBot.define do
  factory :membership_request do
    association :requestor, factory: :user
    association :organization, factory: :organization

    decided_by { Faker::Name.first_name }
    decided_at { Faker::Date.backward }
  end
end
