# frozen_string_literal: true

FactoryBot.define do
  factory :package_document_type do
    name { Faker::Computer.platform }

    trait :nod do
      name { Constants.PACKAGE_DOCUMENT_TYPES.NOD }
    end
  end
end
