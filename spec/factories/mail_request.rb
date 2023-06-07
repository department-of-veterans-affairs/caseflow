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
    country_code { "US"}
    postal_code { "12345" }
    state { "FL" }
    treat_line_2_as_addressee { false }
    treat_line_3_as_addressee { false }
  end

  factory :invalid_mail_request do
    recipient_type { "person" }
    first_name { "Bob" }
    participant_id { "487470002" }
    address_line_1 { "1234 Main Street" }
    city { "Orlando" }
    country_code { "US"}
    postal_code { "12345" }
    state { "FL" }
    treat_line_2_as_addressee { false }
    treat_line_3_as_addressee { false }
  end
end
