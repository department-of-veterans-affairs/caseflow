# frozen_string_literal: true

FactoryBot.define do
  factory :event_record do
    id { Faker::Number.unique.number(digits: 4) } # Unique id
    event_id { Faker::Number.number(digits: 4) }  # Random event ID
    created_at { Faker::Time.backward(days: 1, period: :evening) } # Time within the last day
    updated_at { created_at } # Same as created_at for simplicity
    evented_record_type { "Person" } # The type of the evented record
    evented_record_id { Faker::Number.number(digits: 4) } # Random record ID

    # Info containing both before_data and record_data (which can differ)
    info do
      {
        "before_data" => before_data,
        "record_data" => record_data, # Different from before_data
        "update_type" => "U" # Update type, can be "U" or "I"
      }
    end

    trait :person do
      evented_record_type { "Person" }
    end

    trait :veteran do
      evented_record_type { "Veteran" }
    end
  end

  # Helper factory for generating the `before_data` structure
  factory :before_data, class: Hash do
    id { Faker::Number.number(digits: 4) } # Same as evented_record_id
    participant_id { Faker::Number.number(digits: 9) } # Random participant ID
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 100).to_s } # Random date of birth
    created_at { Faker::Time.backward(days: 1, period: :evening) } # Timestamp for record creation
    updated_at { created_at } # Same timestamp for simplicity
    first_name { Faker::Name.first_name } # Random first name
    last_name { Faker::Name.last_name } # Random last name
    middle_name { nil } # Middle name is optional
    name_suffix { nil } # Suffix is optional
    email_address { Faker::Internet.email } # Random email address
    ssn { Faker::Number.number(digits: 9).to_s } # Random SSN as string
  end

  # Helper factory for generating the `record_data` structure (can differ from `before_data`)
  factory :record_data, class: Hash do
    id { Faker::Number.number(digits: 4) } # Different or same as evented_record_id
    participant_id { Faker::Number.number(digits: 9) } # Random participant ID (can differ)
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 100).to_s } # Random date of birth
    created_at { Faker::Time.backward(days: 1, period: :evening) } # Timestamp for record creation
    updated_at { Faker::Time.backward(days: 1, period: :evening) } # Different timestamp for update
    first_name { Faker::Name.first_name } # Random first name
    last_name { Faker::Name.last_name } # Random last name
    middle_name { nil } # Middle name is optional
    name_suffix { nil } # Suffix is optional
    email_address { Faker::Internet.email } # Random email address
    ssn { Faker::Number.number(digits: 9).to_s } # Random SSN as string
  end
end
