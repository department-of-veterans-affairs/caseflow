# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution_destination do
    address_line_1
    address_line_2
    address_line_3
    address_line_4
    address_line_5
    address_line_6
    city
    country_code
    country_name
    created_at
    created_by_id
    destination_type
    email_address
    phone_number
    postal_code
    state
    treat_line_2_as_addressee
    treat_line_3_as_addressee
    updated_at
    updated_by_id
    vbms_distribution_id
  end
end
