# frozen_string_literal: true

class HearingLocation < ApplicationRecord
  belongs_to :hearing, polymorphic: true

  def street_address
    addr = Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[facility_id]
    %w[address_1 address_2 address_3].map { |line| addr[line] }.reject(&:blank?).join(", ")
  end
end
