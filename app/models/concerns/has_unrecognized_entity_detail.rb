# frozen_string_literal: true

# This Concern attaches the fields of an UnrecognizedEntityDetail, which is business-logic agnostic,
# to a model that "owns" it. The owner must implement an `unrecognized_entity_detail` method, which
# typically may be done by declaring `belongs_to :unrecognized_entity_detail`.

module HasUnrecognizedEntityDetail
  extend ActiveSupport::Concern

  included do
    delegate :name, :first_name, :middle_name, :last_name, :suffix,
             :street_address_1, :street_address_2, :street_address_3,
             :city, :state, :zipcode, :country,
             :phone_number, :email,
             to: :unrecognized_entity_detail
  end
end
