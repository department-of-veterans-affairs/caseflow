class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_as :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = 500

  def veterans
    @veterans ||= Veteran.where(file_number: file_numbers)
      .left_outer_joins(:available_hearing_locations)
      .where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.month.ago)
      .limit(QUERY_LIMIT)
  end

  def file_numbers
    # TODO: will ned an AMA equivalent of this query
    @file_numbers ||= VACOLS::Case.where(bfcurloc: 57).pluck(:bfcorlid).map do |bfcorlid|
      LegacyAppeal.veteran_file_number_from_bfcorlid(bfcorlid)
    end
  end

  def missing_veteran_file_numbers
    existing_veteran_file_numbers = Veteran.where(file_number: file_numbers).pluck(:file_number)
    (file_numbers - existing_veteran_file_numbers)[0, (QUERY_LIMIT - existing_veteran_file_numbers.length)]
  end

  def create_missing_veterans
    missing_veteran_file_numbers.each do |file_number|
      Veteran.find_or_create_by_file_number(file_number)
    end
  end

  def find_or_update_ro_for_veteran(veteran, va_dot_gov_address:)
    veteran.closest_regional_office || fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address)
  end

  def create_available_locations_for_veteran(veteran, va_dot_gov_address:, ids:)
    VADotGovService.get_distance(lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: ids)
      .each do |alternate_hearing_location|
        AvailableHearingLocations.where(veteran_file_number: veteran.file_number).delete_all
        AvailableHearingLocations.create(
          veteran_file_number: veteran.file_number,
          distance: alternate_hearing_location[:distance],
          facility_id: alternate_hearing_location[:id],
          name: alternate_hearing_location[:name],
          address: alternate_hearing_location[:address],
          city: alternate_hearing_location[:address]["city"],
          state: alternate_hearing_location[:address]["state"],
          zip_code: alternate_hearing_location[:address]["zip"]
        )
      end
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_missing_veterans

    veterans.each do |veteran|
      va_dot_gov_address = VADotGovService.validate_address(
        address_line1: veteran.address_line1,
        address_line2: veteran.address_line2,
        address_line3: veteran.address_line3,
        city: veteran.city,
        state: veteran.state,
        country: veteran.country,
        zip_code: veteran.zip_code
      )

      facility_ids = facility_ids_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address)

      create_available_locations_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address, ids: facility_ids)
    end
  end

  private

  def facility_ids_for_veteran(veteran, va_dot_gov_address:)
    ro = find_or_update_ro_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address)

    RegionalOffice::CITIES[ro][:alternate_locations] || [] << RegionalOffice::CITIES[ro][:facility_locator_id]
  end

  def ro_facility_ids_for_state(state_code)
    RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != state_code }
      .pluck(:facility_locator_id)
  end

  def fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address:)
    state_code = get_state_code(va_dot_gov_address)
    facility_ids = ro_facility_ids_for_state(state_code)

    distances = VADotGovService.get_distance(
      lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids
    )

    closest_ro_index = RegionalOffice::CITIES.values.find_index { |ro| ro[:facility_locator_id] == distances[0][:id] }
    closest_ro = RegionalOffice::CITIES.keys[closest_ro_index]
    veteran.update(closest_regional_office: closest_ro)

    closest_ro
  end

  def valid_states
    @valid_states ||= RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:state)
  end

  def get_state_code(va_dot_gov_address)
    state_code = case va_dot_gov_address[:country_code]
                 # Guam, American Somao, Marshall Islands, Micronesia, Northern Mariana Islands, Palau
                 when "GQ", "AQ", "RM", "FM", "CQ", "PS"
                   "HI"
                 when "PH", "RP", "PI"
                   "PI"
                 when "VI", "VQ", "PR"
                   "PR"
                 when "US"
                   va_dot_gov_address[:state_code]
                 else
                   msg = "#{va_dot_gov_address[:country_code]} is not a valid country code."
                   fail Caseflow::Error::FetchHearingLocationsJobError, code: 500, message: msg
                 end

    return state_code if valid_states.include?(state_code)

    msg = "#{state_code} is not a valid state code."
    fail Caseflow::Error::FetchHearingLocationsJobError, code: 500, message: msg
  end
end
