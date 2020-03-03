# frozen_string_literal: true

class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :address_line_3, :city, :country, :state, :zip

  def address
    return nil unless found?

    # The address from BGS includes a type field. Filter the hash keys to only include
    # address components (for Address#new).
    bgs_record.slice(
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :city,
      :zip,
      :country,
      :state
    )
  end

  def fetch_bgs_record
    cache_key = "bgs-participant-address-#{participant_id}"
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      bgs.find_address_by_participant_id(participant_id)
    rescue Savon::Error
      # If there is no address for this participant id then we get an error.
      # catch it and return an empty array
      nil
    end
  end

  def bgs
    BGSService.new
  end
end
