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
    # TODO: will need an AMA equivalent of this query
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

  def fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address:)
    state_code = get_state_code(va_dot_gov_address)
    facility_ids = ro_facility_ids_for_state(state_code)

    distances = VADotGovService.get_distance(
      lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids
    )

    closest_ro_index = RegionalOffice::CITIES.values.find_index { |ro| ro[:facility_locator_id] == distances[0][:id] }
    closest_ro = RegionalOffice::CITIES.keys[closest_ro_index]
    veteran.update(closest_regional_office: closest_ro)

    { closest_regional_office: closest_ro, facility: distances[0] }
  end

  def create_available_locations_for_veteran(veteran, va_dot_gov_address:)
    ro = fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address)
    facility_ids = facility_ids_for_ro(ro[:closest_regional_office])

    if !ro[:facility].nil? && facility_ids.length == 1
      create_available_location_by_file_number(veteran.file_number, facility: ro[:facility])
    else
      VADotGovService.get_distance(lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids)
        .each do |alternate_hearing_location|
          create_available_location_by_file_number(veteran.file_number, facility: alternate_hearing_location)
        end
    end
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_missing_veterans

    veterans.each do |veteran|
      begin
        va_dot_gov_address = validate_veteran_address(veteran)
      rescue Caseflow::Error::VaDotGovLimitError
        sleep 60
        va_dot_gov_address = validate_veteran_address(veteran)
      end

      create_available_locations_for_veteran(veteran, va_dot_gov_address: va_dot_gov_address)
    end
  end

  private

  def validate_veteran_address(veteran)
    VADotGovService.validate_address(
      address_line1: veteran.address_line1,
      address_line2: veteran.address_line2,
      address_line3: veteran.address_line3,
      city: veteran.city,
      state: veteran.state,
      country: veteran.country,
      zip_code: veteran.zip_code
    )
  end

  def facility_ids_for_ro(regional_office_id)
    RegionalOffice::CITIES[regional_office_id][:alternate_locations] ||
      [] << RegionalOffice::CITIES[regional_office_id][:facility_locator_id]
  end

  def ro_facility_ids_for_state(state_code)
    RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != state_code }
      .pluck(:facility_locator_id)
  end

  def valid_states
    @valid_states ||= RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:state)
  end

  def create_available_location_by_file_number(file_number, facility:)
    AvailableHearingLocations.where(veteran_file_number: file_number).destroy_all
    AvailableHearingLocations.create(
      veteran_file_number: file_number,
      distance: facility[:distance],
      facility_id: facility[:id],
      name: facility[:name],
      address: facility[:address],
      city: facility[:city],
      state: facility[:state],
      zip_code: facility[:zip_code],
      classification: facility[:classification],
      facility_type: facility[:facility_type]
    )
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
