class VaDotGovAddressValidator
  attr_accessor :appeal

  def initialize(appeal:)
    @appeal = appeal
  end

  def validate
    if address.nil?
      fail Caseflow::Error::VaDotGovValidatorError, code: 500, message: "InvalidRequestStreetAddress"
    end

    begin
      valid_address = validate_appellant_address
    rescue Caseflow::Error::VaDotGovLimitError => error
      raise error
    rescue Caseflow::Error::VaDotGovAPIError => error
      valid_address = validate_zip_code
      raise error if valid_address.nil?
    end

    valid_address
  end

  def create_available_hearing_locations(va_dot_gov_address:)
    ro = fetch_and_update_ro(va_dot_gov_address: va_dot_gov_address)
    facility_ids = facility_ids_for_ro(ro[:closest_regional_office])
    AvailableHearingLocations.where(appeal: appeal).destroy_all

    if facility_ids.length == 1
      create_available_hearing_location(facility: ro[:facility])
    else
      sleep 1
      VADotGovService.get_distance(lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids)
        .each do |alternate_hearing_location|
          create_available_hearing_location(facility: alternate_hearing_location)
        end
    end
  end

  private

  def address
    @address ||= appeal.is_a?(LegacyAppeal) ? appeal.appellant[:address] : appeal.appellant.address
  end

  def validate_appellant_address
    VADotGovService.validate_address(
      address_line1: address[:address_line1],
      address_line2: address[:address_line2],
      address_line3: address[:address_line3],
      city: address[:city],
      state: address[:state],
      country: address[:country],
      zip_code: address[:zip_code]
    )
  end

  def validate_zip_code
    if address[:zip].nil? || address[:state].nil? || address[:country].nil?
      nil
    else
      lat_lng = ZipCodeToLatLngMapper::MAPPING[address[:zip][0..4]]

      return nil if lat_lng.nil?

      { lat: lat_lng[0], long: lat_lng[1], country_code: address[:country], state_code: address[:state] }
    end
  end

  def fetch_and_update_ro(va_dot_gov_address:)
    state_code = get_state_code(va_dot_gov_address)
    facility_ids = ro_facility_ids_for_state(state_code)

    distances = VADotGovService.get_distance(ids: facility_ids, lat: va_dot_gov_address[:lat],
                                             long: va_dot_gov_address[:long])
    closest_ro = RegionalOffice::CITIES.find { |_k, v| v[:facility_locator_id] == distances[0][:facility_id] }[0]

    appeal.update(closest_regional_office: except_delaware(closest_ro))

    { closest_regional_office: closest_ro, facility: distances[0] }
  end

  def facility_ids_for_ro(regional_office_id)
    (RegionalOffice::CITIES[regional_office_id][:alternate_locations] ||
      []) << RegionalOffice::CITIES[regional_office_id][:facility_locator_id]
  end

  def ro_facility_ids_for_state(state_code)
    filter_states = if %w[VA MD].include? state_code
                      ["DC", state_code]
                    else
                      [state_code]
                    end
    RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || !filter_states.include?(ro[:state]) }
      .pluck(:facility_locator_id)
  end

  def valid_states
    @valid_states ||= RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:state)
  end

  def create_available_hearing_location(facility:)
    AvailableHearingLocations.create(
      veteran_file_number: appeal.veteran_file_number || "",
      appeal: appeal,
      distance: facility[:distance],
      facility_id: facility[:facility_id],
      name: facility[:name],
      address: facility[:address],
      city: facility[:city],
      state: facility[:state],
      zip_code: facility[:zip_code],
      classification: facility[:classification],
      facility_type: facility[:facility_type]
    )
  end

  def get_state_code(va_dot_gov_address) # rubocop:disable Metrics/CyclomaticComplexity
    return "DC" if appeal.is_a?(LegacyAppeal) && appeal.hearing_request_type == :central_office

    state_code = case va_dot_gov_address[:country_code]
                 # Guam, American Samoa, Marshall Islands, Micronesia, Northern Mariana Islands, Palau
                 when "GQ", "AQ", "RM", "FM", "CQ", "PS"
                   "HI"
                 # Philippine Islands
                 when "PH", "RP", "PI"
                   "PI"
                 # Puerto Rico, Vieques, U.S. Virgin Islands
                 when "VI", "VQ", "PR"
                   "PR"
                 when "US", "USA"
                   va_dot_gov_address[:state_code]
                 else
                   fail Caseflow::Error::VaDotGovValidatorError, code: 500, message: "ForeignVeteranCase"
                 end

    return state_code if valid_states.include?(state_code)

    fail Caseflow::Error::VaDotGovValidatorError, code: 500, message: "ForeignVeteranCase"
  end

  def except_delaware(closest_regional_office)
    # Delaware's RO is not actually an RO
    # So we assign all appeals with appellants that live in Delaware to Philadelphia
    (closest_regional_office == "RO60") ? "RO10" : closest_regional_office
  end
end
