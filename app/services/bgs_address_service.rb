# frozen_string_literal: true

class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :address_line_3, :city, :country, :state, :zip

  def address
    return nil unless found?

    bgs_record
  end

  def fetch_bgs_record
    bgs.find_address_by_participant_id(participant_id)
  rescue Savon::Error
    # If there is no addresses for this participant id then we get an error.
    # catch it and return an empty array
    nil
  end

  def bgs
    BGSService.new
  end
end
