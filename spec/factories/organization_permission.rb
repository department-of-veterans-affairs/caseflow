# frozen_string_literal: true

FactoryBot.define do
  factory :organization_permission do
    description { Faker::Hipster.sentence }
    enabled { false }
    permission { Faker::ProgrammingLanguage.name }
    default_for_admin { false }
    association :organization, factory: :organization
  end
end
