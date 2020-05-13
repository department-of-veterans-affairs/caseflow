# frozen_string_literal: true

class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :address_line_3, :city, :country, :state, :zip

  class << self
    def cache_key_for_participant_id(participant_id)
      "bgs-participant-address-#{participant_id}"
    end

    def participant_id_from_cache_key(key)
      key.split("-")[-1]
    end

    def fetch_cached_addresses(participant_ids)
      keys = participant_ids.map { |id| cache_key_for_participant_id(id) }
      addresses = Rails.cache.read_multi(*keys)
      Hash[addresses.map { |k, v| [participant_id_from_cache_key(k), v] }]
    end
  end

  def address
    return nil unless found?

    # The address from BGS includes a type field. Filter the hash keys to only include
    # address components (for Address#new).
    {
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      city: city,
      zip: zip,
      country: country,
      state: state
    }
  end

  def fetch_bgs_record
    cache_key = self.class.cache_key_for_participant_id(participant_id)
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
