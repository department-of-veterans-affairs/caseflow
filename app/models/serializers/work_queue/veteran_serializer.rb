# frozen_string_literal: true

class WorkQueue::VeteranSerializer < ActiveModel::Serializer
  attribute :full_name do
    object.veteran_full_name
  end
  attribute :gender do
    object.veteran_gender
  end
  attribute :date_of_birth do
    object.veteran ? object.veteran.date_of_birth : nil
  end
  attribute :date_of_death do
    object.veteran ? object.veteran.date_of_death : nil
  end
  attribute :address do
    if object.veteran_address_line_1
      {
        address_line_1: object.veteran_address_line_1,
        address_line_2: object.veteran_address_line_2,
        address_line_3: object.veteran_address_line_3,
        city: object.veteran_city,
        state: object.veteran_state,
        zip: object.veteran_zip,
        country: object.veteran_country
      }
    end
  end
  attribute :regional_office do
    if object.regional_office
      {
        key: object.regional_office.key,
        city: object.regional_office.city,
        state: object.regional_office.state
      }
    end
  end
end
