# frozen_string_literal: true
FactoryBot.define do
  factory :event_record do
    id { Faker::Number.unique.number(digits: 4) }
    event { create(:event) } # Automatically create an associated event record
    event_id { event.id } # Ensure the event_id is set to the created event's ID
    created_at { Faker::Time.backward(days: 1, period: :evening) }
    updated_at { created_at }
    evented_record_type { "Person" }
    evented_record_id { Faker::Number.number(digits: 4) }
    # Info containing both before_data and record_data (which can differ)
    info do
      {
        "before_data" => FactoryBot.attributes_for(:before_data), # Use the `attributes_for` method to generate the hash
        "record_data" => FactoryBot.attributes_for(:record_data), # Use `attributes_for` here as well
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
