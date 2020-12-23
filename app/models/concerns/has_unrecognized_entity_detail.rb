# frozen_string_literal: true

# This Concern attaches the fields of an UnrecognizedEntityDetail, which is business-logic agnostic,
# to a model that "owns" it. The owner must implement an `unrecognized_entity_detail` method, which
# typically may be done by declaring `belongs_to :unrecognized_entity_detail`.

module HasUnrecognizedEntityDetail
  extend ActiveSupport::Concern

  included do
    delegate :name, :first_name, :middle_name, :last_name, :suffix,
             :address, :address_line_1, :address_line_2, :address_line_3,
             :city, :state, :zip, :country,
             :phone_number, :email_address,
             to: :unrecognized_entity_detail,
             allow_nil: true
  end
end
