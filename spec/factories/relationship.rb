# frozen_string_literal: true

FactoryBot.define do
  factory :relationship do
    participant_id { generate :participant_id }
    veteran_file_number { create(:veteran).file_number }
    first_name { Faker::Name.first_name.upcase.tr("\'", "") }
    last_name { Faker::Name.last_name.downcase.tr("\'", "") }

    trait :spouse do
      relationship_type { "Spouse" }
    end

    trait :child do
      relationship_type { "Child" }
    end

    trait :other do
      relationship_type { "Other" }
    end
  end
end
