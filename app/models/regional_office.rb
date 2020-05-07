# frozen_string_literal: true

def convert_top_level_key_to_string(hash)
  hash.keys.map { |key| [key.to_s, hash[key]] }.to_h
end

class RegionalOffice
  class NotFoundError < StandardError; end

  MULTIPLE_ROOM_ROS = %w[RO17 RO18].freeze
  MULTIPLE_NUM_OF_RO_ROOMS = 2
  DEFAULT_NUM_OF_RO_ROOMS = 1

  # Maps CSS Station # to RO id
  STATIONS = convert_top_level_key_to_string(Constants.REGIONAL_OFFICE_FOR_CSS_STATION.to_h).freeze

  CITIES = convert_top_level_key_to_string(Constants.REGIONAL_OFFICE_INFORMATION.to_h).freeze

  ROS = CITIES.keys.freeze

  SATELLITE_OFFICES = convert_top_level_key_to_string(Constants.SATELLITE_OFFICE_INFORMATION.to_h).freeze

  # The string key is a unique identifier for a regional office.
  attr_reader :key

  def initialize(key)
    @key = key
  end

  def station_key
    @station_key ||= compute_station_key
  end

  def city
    location_hash[:city]
  end

  def state
    location_hash[:state]
  end

  def timezone
    location_hash[:timezone]
  end

  def name
    location_hash[:label]
  end

  def facility_id
    location_hash[:facility_locator_id]
  end

  def street_address
    facility_location_hash["address_1"]
  end

  def full_address
    full_addr = [street_address, facility_location_hash["address_2"], facility_location_hash["address_3"]]
      .reject(&:blank?).join(" ")

    return if full_addr.blank?

    "#{full_addr}, #{[city, state, zip_code].reject(&:blank?).join(' ')}"
  end

  def zip_code
    facility_location_hash["zip"]
  end

  def to_h
    location_hash.merge(key: key)
  end

  def station_description
    "Station #{station_key} - #{city}"
  end

  def valid?
    !!location_hash[:city]
  end

  private

  def location_hash
    @location_hash ||= compute_location_hash
  end

  def facility_location_hash
    if facility_id.present?
      addr = Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[facility_id]

      return addr if addr.present?
    end

    {}
  end

  def compute_location_hash
    CITIES[key] || SATELLITE_OFFICES[key] || {}
  end

  def compute_station_key
    result = STATIONS.find { |_station, ros| [*ros].include? key }
    result&.first
  end

  class << self
    # Returns a regional office with the specified key,
    # throws an error if not found
    def find!(key)
      result = RegionalOffice.new(key)

      fail NotFoundError unless result.valid?

      result
    end

    def all
      Enumerator.new do |iter|
        CITIES.each_key { |ro_key| iter << RegionalOffice.new(ro_key) }
        SATELLITE_OFFICES.each_key { |ro_key| iter << RegionalOffice.new(ro_key) }
      end
    end

    def city_state_by_key(ro_key)
      regional_office = RegionalOffice.find!(ro_key)

      "#{regional_office.city}, #{regional_office.state}"
    rescue NotFoundError
      nil
    end

    def ros_with_hearings
      CITIES.select { |_key, value| value[:hold_hearings] }
    end

    # Returns RegionalOffice objects for each RO that has the passed station code
    def for_station(station_key)
      [STATIONS[station_key]].flatten.map do |regional_office_key|
        find!(regional_office_key)
      end
    end

    def facility_ids
      ids = []

      CITIES.values.each do |city|
        ids << city[:facility_locator_id] if city[:facility_locator_id].present?
        ids += city[:alternate_locations] if city[:alternate_locations].present?
      end

      ids.uniq
    end

    def facility_ids_for_ro(regional_office_key)
      (
        (CITIES[regional_office_key][:alternate_locations] || []) << CITIES[regional_office_key][:facility_locator_id]
      ).uniq
    end
  end
end
