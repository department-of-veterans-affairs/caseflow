# frozen_string_literal: true

# This Concern attaches the fields of an UnrecognizedPartyDetail, which is business-logic agnostic,
# to a model that "owns" it. The owner must implement an `unrecognized_party_detail` method, which
# typically may be done by declaring `belongs_to :unrecognized_party_detail`.

module HasUnrecognizedPartyDetail
  extend ActiveSupport::Concern

  included do
    delegate :name, :first_name, :middle_name, :last_name, :suffix,
             :address, :address_line_1, :address_line_2, :address_line_3,
             :city, :state, :zip, :country, :date_of_birth,
             :phone_number, :email_address, :party_type,
             to: :unrecognized_party_detail,
             allow_nil: true
  end
end
