# frozen_string_literal: true

FactoryBot.define do
  factory :membership_request do
    association :user, factory: :user
    association :organization, factory: :organization

    status { "assigned" }
    closed_by_user_id { Faker::Name.first_name }
    closed_at_datetime { Faker::Date.backward }
  end
end
