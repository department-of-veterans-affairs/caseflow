# frozen_string_literal: true

class WorkQueue::VeteranSerializer
  include FastJsonapi::ObjectSerializer

  attribute :full_name, &:veteran_full_name
  attribute :gender, &:veteran_gender
  attribute :date_of_birth do |object|
    object.veteran&.date_of_birth
  end
  attribute :date_of_death do |object|
    object.veteran&.date_of_death
  end
  attribute :email_address do |object|
    object.veteran&.email_address
  end
  attribute :address do |object|
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

  attribute :relationships do |object, params|
    if params[:relationships].to_s == "true" && object.veteran&.relationships
      object.veteran&.relationships&.map(&:serialize)
    end
  end
end
