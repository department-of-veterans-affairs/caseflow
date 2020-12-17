# frozen_string_literal: true

module HasUnrecognizedEntityDetail
  extend ActiveSupport::Concern

  included do
    belongs_to :unrecognized_entity_detail

    delegate :name, :first_name, :middle_name, :last_name, :suffix,
             :street_address_1, :street_address_2, :street_address_3,
             :city, :state, :zipcode, :country,
             :phone_number, :email,
             to: :unrecognized_entity_detail
  end
end
