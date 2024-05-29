# frozen_string_literal: true

class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :address_line_3, :city, :country, :state, :zip, :email_addrs

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
      addresses.transform_keys { |k| participant_id_from_cache_key(k) }
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

  def email_address
    return nil unless found?

    email_addrs
  end

  def cache_key
    self.class.cache_key_for_participant_id(participant_id)
  end

  def fetch_bgs_record
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      bgs.find_address_by_participant_id(participant_id)
    rescue Savon::Error => error
      Raven.capture_exception(error)
      Rails.logger.warn("Failed to fetch address from BGS for participant id: #{participant_id}: #{error}")
      # If there is no address for this participant id then we get an error.
      # catch it and return an empty array
      nil
    end
  end

  def refresh_cached_bgs_record
    Rails.cache.delete(cache_key)
    fetch_bgs_record
  end

  def bgs
    BGSService.new
  end
end
