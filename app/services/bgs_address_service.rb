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

  def zip
    zip_code = @zip

    # Write to cache for research purposes. Will remove!
    # See:
    #   https://github.com/department-of-veterans-affairs/caseflow/issues/13889
    Rails.cache.write("person-zip-#{zip_code}", true) if zip_code.present?

    return zip_code
  end

  def state
    state = @state

    # Write to cache for research purposes. Will remove!
    # See:
    #   https://github.com/department-of-veterans-affairs/caseflow/issues/13889
    Rails.cache.write("person-state-#{state}", true) if state.present?

    return state
  end

  def country
    country = @country

    # Write to cache for research purposes. Will remove!
    # See:
    #   https://github.com/department-of-veterans-affairs/caseflow/issues/13889
    Rails.cache.write("person-country-#{country}", true) if country.present?

    return country
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
