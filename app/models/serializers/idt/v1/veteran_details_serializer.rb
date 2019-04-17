# frozen_string_literal: true

class Idt::V1::VeteranDetailsSerializer
  include FastJsonapi::ObjectSerializer

  attribute :name
  attribute :name_suffix
  attribute :gender
  attribute :date_of_birth
  attribute :date_of_death
  attribute :address_line_1
  attribute :address_line_2
  attribute :address_line_3
  attribute :city
  attribute :state
  attribute :zip
  attribute :country
  attribute :file_number
  attribute :participant_id

  attribute :poa do |_veteran, params|
    params[:poa]
  end
end
