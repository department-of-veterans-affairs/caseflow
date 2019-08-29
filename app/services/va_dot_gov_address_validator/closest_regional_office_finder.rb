# frozen_string_literal: true

# a facility id can be both an alternate location and an RO
# and could also be an alternate location for more than one RO
# find all possible ROs for the facility id and sort by distance

class VaDotGovAddressValidator::ClosestRegionalOfficeFinder
  attr_reader :facilities, :closest_facility_id

  def initialize(facilities:, closest_facility_id:)
    @facilities = facilities
    @closest_facility_id = closest_facility_id
  end

  def call
    fail_if_distances_missing
    possible_regional_offices_distances.min_by { |ro| ro[:distance] }.dig(:regional_office_key)
  end

  private

  def fail_if_distances_missing
    if possible_regional_offices_distances.any? { |ro| ro[:distance].nil? }
      fail Caseflow::SerializableError, code: 500, message: "Distances are missing from possible regional office."
    end
  end

  def possible_regional_offices
    RegionalOffice::CITIES.select do |_key, val|
      val[:facility_locator_id] == closest_facility_id ||
        val[:alternate_locations]&.include?(closest_facility_id)
    end
  end

  def possible_regional_offices_distances
    possible_regional_offices.map do |regional_office_key, val|
      regional_office_facility = facilities_hash[val[:facility_locator_id]]
      val.merge(
        distance: regional_office_facility[:distance],
        regional_office_key: regional_office_key
      )
    end
  end

  def facilities_hash
    @facilities_hash ||= begin
      facility_tuples = facilities.map { |facility| [facility[:facility_id], facility] }
      Hash[facility_tuples]
    end
  end
end
