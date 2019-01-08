class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def veterans
    @veterans ||= Veteran.where(file_number: file_numbers)
      .left_outer_joins(:available_hearing_locations)
      .where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.month.ago)
      .limit(500)
  end

  def file_numbers
    @file_numbers ||= VACOLS::Case.where(bfcurloc: 57).pluck(:bfcorlid).map do |bfcorlid|
      LegacyAppeal.veteran_file_number_from_bfcorlid(bfcorlid)
    end
  end

  def missing_veteran_file_numbers
    existing_veteran_file_numbers = Veteran.where(file_number: file_numbers).pluck(:file_number)
    file_numbers - existing_veteran_file_numbers
  end

  def create_missing_veterans
    missing_veteran_file_numbers.each do |file_number|
      Veteran.find_or_create_by_file_number(file_number)
    end
  end

  def find_or_update_ro_for_veteran(veteran, lat, long)
    veteran.hearing_regional_office ||
      find_legacy_ro_and_update_for_veteran(veteran) ||
      fetch_and_update_ro_for_veteran(veteran, lat, long)
  end

  def create_available_locations_for_veteran(veteran, lat, long, ids)
    VADotGovService.get_distance(lat: lat, long: long, ids: ids).each do |alternate_hearing_location|
      AvailableHearingLocations.create(
        veteran_file_number: veteran.file_number,
        distance: alternate_hearing_location[:distance],
        facility_id: alternate_hearing_location[:id],
        name: alternate_hearing_location[:name],
        address: full_address_for(alternate_hearing_location[:address]),
        city: alternate_hearing_location[:address]["city"],
        state: alternate_hearing_location[:address]["state"],
        zip_code: alternate_hearing_location[:address]["zip"]
      )
    end
  end

  def perform
    create_missing_veterans

    veterans.each do |veteran|
      lat, long = VADotGovService.geocode(
        address_line1: veteran.address_line1,
        address_line2: veteran.address_line2,
        address_line3: veteran.address_line3,
        city: veteran.city,
        state: veteran.state,
        country: veteran.country,
        zip_code: veteran.zip_code
      )

      facility_ids = facility_ids_for_veteran(veteran, lat, long)

      create_available_locations_for_veteran(veteran, lat, long, facility_ids)
    end
  end

  private

  def ro_facility_ids
    @ro_facility_ids ||=
      RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:facility_locator_id)
  end

  def bfcorlid_to_ro_hash
    @bfcorlid_to_ro_hash ||= begin
      bfcorlids = veterans.pluck(:file_number).map do |file_number|
        LegacyAppeal.convert_file_number_to_vacols(file_number)
      end

      VACOLS::Case.where(bfcorlid: bfcorlids).pluck(:bfcorlid, :bfregoff).to_h
    end
  end

  def facility_ids_for_veteran(veteran, lat, long)
    ro = find_or_update_ro_for_veteran(veteran, lat, long)

    RegionalOffice::CITIES[ro][:alternate_locations] || [] << RegionalOffice::CITIES[ro][:facility_locator_id]
  end

  def find_legacy_ro_and_update_for_veteran(veteran)
    ro = bfcorlid_to_ro_hash[LegacyAppeal.convert_file_number_to_vacols(veteran.file_number)]

    veteran.update(hearing_regional_office: ro) unless ro.nil?

    ro
  end

  def fetch_and_update_ro_for_veteran(veteran, lat, long)
    distances = VADotGovService.get_distance(lat: lat, long: long, ids: ro_facility_ids)

    unless distances.empty?
      closest_ro_index = RegionalOffice::CITIES.values.find_index { |ro| ro[:facility_locator_id] == distances[0][:id] }
      closest_ro = RegionalOffice::CITIES.keys[closest_ro_index]
      veteran.update(hearing_regional_office: closest_ro)

      return closest_ro
    end

    nil
  end

  def full_address_for(address)
    address_1 = address["address_1"]
    address_2 = address["address_2"].blank? ? "" : " " + address["address_2"]
    address_3 = address["address_3"].blank? ? "" : " " + address["address_3"]

    "#{address_1}#{address_2}#{address_3}"
  end
end
