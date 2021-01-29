# frozen_string_literal: true

class Idt::V1::VeteranDetailsSerializer
  include JSONAPI::Serializer
  set_id do
    1
  end

  attribute :claimant do |object|
    {
      first_name: object[:first_name],
      last_name: object[:last_name],
      date_of_birth: object[:date_of_birth],
      date_of_death: object[:date_of_death],
      name_suffix: object[:name_suffix],
      sex: object[:sex],
      address_line_1: object[:address_line1],
      address_line_2: object[:address_line2],
      address_line_3: object[:address_line3],
      country: object[:country],
      zip: object[:zip_code],
      state: object[:state],
      city: object[:city],
      file_number: object[:file_number],
      participant_id: Rails.env.test? ? object[:participant_id] : object[:ptcpnt_id]
    }
  end

  attribute :poa do |_veteran, params|
    params[:poa]
  end
end
