# frozen_string_literal: true

def convert_top_level_key_to_string(hash)
  hash.keys.map { |key| [key.to_s, hash[key]] }.to_h
end

class RegionalOffice
  class NotFoundError < StandardError; end

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

  def alternate_locations
    location_hash[:alternate_locations]
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

  def facility_id?
    facility_id.present?
  end

  def valid?
    !!location_hash[:timezone] # the timezone field is currently set for all ROs
  end

  def virtual?
    key == HearingDay::REQUEST_TYPES[:virtual]
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
    STATIONS.detect { |_station, ros| ros.include?(key) }&.first
  end

  class << self
    # Gets a regional office with the specified key,
    #
    # @param ro_key  [String] The RO key
    #
    # @return            [RegionalOffice]
    #   The RO if it is found.
    #
    # @raise      [RegionalOffice::NotFoundError]
    #   If an RO with the specified key was not found
    def find!(ro_key)
      result = RegionalOffice.new(ro_key)

      fail NotFoundError, "Could not find Regional Office with key (#{ro_key})" unless result.valid?

      result
    end

    # Get all regional offices (including satellite offices).
    #
    # @return            [Enumerator<RegionalOffice>]
    #   An enumerator over all ROs (including satellite offices).
    def all
      Enumerator.new do |iter|
        CITIES.each_key { |ro_key| iter << RegionalOffice.new(ro_key) }
        SATELLITE_OFFICES.each_key { |ro_key| iter << RegionalOffice.new(ro_key) }
      end
    end

    # Get regional offices (excluding satellite offices).
    #
    # @return            [Enumerator<RegionalOffice>]
    #   An enumerator over ROs (excluding satellite offices).
    def cities
      Enumerator.new do |iter|
        CITIES.each_key { |ro_key| iter << RegionalOffice.new(ro_key) }
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
    #
    # @param station_key  [String] A CSS station code
    #
    # @return            [Array<RegionalOffice>]
    #   An array of regional offices associated with the station.
    def for_station(station_key)
      # STATIONS[station_key] can return either an array of RO keys or a single RO key
      [STATIONS[station_key]]
        .flatten
        .map(&RegionalOffice.method(:find!))
    end

    def facility_ids
      ids = []

      CITIES.values.each do |city|
        ids << city[:facility_locator_id] if city[:facility_locator_id].present?
        ids += city[:alternate_locations] if city[:alternate_locations].present?
      end

      ids.uniq
    end

    # Get facility IDs for ROs (excludes satellite offices).
    #
    # @return            [Array<String>]
    #   An array of facility ids.
    def ro_facility_ids
      cities
        .select(&:facility_id?)
        .map(&:facility_id)
        .uniq
    end

    # Get all RO facility IDs for a given state (excludes satellite offices).
    #
    # @param state_code  [String] A 2-letter state code
    #
    # @return            [Array<String>]
    #   An array of facility ids that correspond to the matched ROs.
    def ro_facility_ids_for_state(state_code)
      cities
        .select { |ro| ro.facility_id? && state_code == ro.state }
        .map(&:facility_id)
        .uniq
    end

    # Get all facility IDs (including alternate locations) that correspond with an RO
    # (excludes satellite offices).
    #
    # @param regional_office_key  [String] The RO key
    #
    # @return                     [Array<String>]
    #   An array of facility ids that correspond to the matched RO.
    def facility_ids_for_ro(regional_office_key)
      (
        (CITIES[regional_office_key][:alternate_locations] || []) << CITIES[regional_office_key][:facility_locator_id]
      ).uniq
    end
  end
end
