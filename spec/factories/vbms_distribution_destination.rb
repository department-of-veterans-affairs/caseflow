# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution_destination do
    address_line_1 { "POSTMASTER GENERAL" }
    address_line_2 { "UNITED STATES POSTAL SERVICE" }
    address_line_3 { "475 LENFANT PLZ SW RM 10022" }
    address_line_4 { "SUITE 123" }
    address_line_5 { "APO AE 09001-5275" }
    address_line_6 { nil }
    city { "WASHINGTON DC" }
    country_code { "us" }
    country_name { "UNITED STATES" }
    created_at { Time.zone.now }
    created_by_id { nil }
    destination_type { "physicalAddress" }
    postal_code { "12345" }
    state { "DC" }
    treat_line_2_as_addressee { true }
    treat_line_3_as_addressee { true }
    updated_at { Time.zone.now }
    updated_by_id { nil }
    vbms_distribution_id { nil }
  end
end
