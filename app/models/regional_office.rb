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

  def to_h
    location_hash.merge(key: key)
  end

  def station_description
    "Station #{station_key} - #{city}"
  end

  def valid?
    !!location_hash[:city]
  end

  def self.city_state_by_key(ro_key)
    regional_office = CITIES[ro_key]
    if regional_office
      "#{regional_office[:city]}, #{regional_office[:state]}"
    end
  end

  private

  def location_hash
    @location_hash ||= compute_location_hash
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
      facility_ids = []
      CITIES.values.each do |val|
        next if !val[:facility_locator_id]

        facility_ids << val[:facility_locator_id]
        facility_ids += val[:alternate_locations] if val[:alternate_locations].present?
      end

      facility_ids.uniq
    end

    def ro_facility_ids
      CITIES.values.select { |ro| ro[:facility_locator_id].present? }.pluck(:facility_locator_id).uniq
    end

    def facility_ids_for_ro(regional_office_key)
      (CITIES[regional_office_key].alternate_locations || []) << CITIES[regional_office_key][:facility_locator_id]
    end

    def ro_facility_ids_for_state(state_code)
      CITIES.values.select do |ro|
        ro[:facility_locator_id].present? && state_code == ro[:state]
      end.pluck(:facility_locator_id).uniq
    end

    def find_ro_by_facility_id(facility_id)
      CITIES.detect do |regional_office_id, val|
        if val[:facility_locator_id] == facility_id
          break regional_office_id
        end
      end
    end
  end
end
