# frozen_string_literal: true

FactoryBot.define do
  factory :mail_request do
    recipient_type { "person" }
    first_name { "Bob" }
    last_name  { "Smithcole" }
    participant_id { "487470002" }
    destination_type { "domesticAddress" }
    address_line_1 { "1234 Main Street" }
    city { "Orlando" }
    country_code { "US" }
    postal_code { "12345" }
    state { "FL" }
    treat_line_2_as_addressee { false }
    treat_line_3_as_addressee { false }

    trait :nil_recipient_type do
      recipient_type { nil }
    end

    trait :ro_colocated_recipient do
      recipient_type { "ro-colocated" }
      first_name { nil }
      last_name  { nil}
      name { "WYOMING VETERANS COMMISSION" }
      poa_code { "869" }
      claimant_station_of_jurisdiction { "329" }
      participant_id { nil }
      destination_type { "derived" }
      address_line_1 { nil }
      city { nil}
      country_code { nil }
      postal_code { nil }
      state { nil }
      treat_line_2_as_addressee { nil }
      treat_line_3_as_addressee { nil }
    end

    initialize_with { new(attributes) }
  end
end
