# frozen_string_literal: true

class VaDotGovAddressValidator
  attr_accessor :appeal

  STATUSES = {
    matched_available_hearing_locations: :matched_available_hearing_locations,
    philippines_exception: :defaulted_to_philippines_RO58,
    created_admin_action: :created_admin_action
  }.freeze

  def initialize(appeal:)
    @appeal = appeal
  end

  def update_closest_ro_and_ahls
    begin
      va_dot_gov_address = validate
    rescue Caseflow::Error::VaDotGovLimitError => error
      raise error
    rescue Caseflow::Error::VaDotGovAPIError => error
      return handle_error(error)
    end

    begin
      create_available_hearing_locations(va_dot_gov_address: va_dot_gov_address)
    rescue StandardError => error
      handle_error(error)
    end
  end

  def assign_ro_and_update_ahls(new_ro)
    appeal.update!(closest_regional_office: new_ro)
    assign_available_hearing_locations_for_ro(regional_office_id: new_ro)
  end

  def validate
    if address.nil?
      fail Caseflow::Error::VaDotGovNullAddressError
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

  def get_distance_to_facilities(facility_ids:)
    va_dot_gov_address = validate

    VADotGovService.get_distance(lat: va_dot_gov_address[:lat],
                                 long: va_dot_gov_address[:long],
                                 ids: facility_ids)
  end

  def assign_available_hearing_locations_for_ro(regional_office_id:)
    facility_ids = facility_ids_for_ro(regional_office_id)
    AvailableHearingLocations.where(appeal: appeal).destroy_all

    VADotGovService.get_facility_data(ids: facility_ids)
      .each do |alternate_hearing_location|
        create_available_hearing_location(facility: alternate_hearing_location)
      end
  end

  def create_available_hearing_locations(va_dot_gov_address:)
    ro = fetch_and_update_ro(va_dot_gov_address: va_dot_gov_address)
    facility_ids = facility_ids_for_ro(ro[:closest_regional_office])
    AvailableHearingLocations.where(appeal: appeal).destroy_all
    available_hearing_locations = []

    if facility_ids.length == 1
      available_hearing_locations << create_available_hearing_location(facility: ro[:facility])
    else
      sleep 1
      VADotGovService.get_distance(lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids)
        .each do |alternate_hearing_location|
          available_hearing_locations << create_available_hearing_location(facility: alternate_hearing_location)
        end
    end

    { status: STATUSES[:matched_available_hearing_locations], available_hearing_locations: available_hearing_locations }
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

  private

  def address
    @address ||= appeal.is_a?(LegacyAppeal) ? appeal.appellant[:address] : appeal.appellant.address
  end

  def validate_appellant_address
    VADotGovService.validate_address(
      address_line1: address[:address_line_1],
      address_line2: address[:address_line_2],
      address_line3: address[:address_line_3],
      city: address[:city],
      state: address[:state],
      country: address[:country],
      zip_code: address[:zip]
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

    closest_facility_id = distances[0][:facility_id]
    closest_ro = get_regional_office_from_facility_id(closest_facility_id)

    appeal.update(closest_regional_office: VaDotGovAddressValidatorExceptions.except_delaware(closest_ro))

    { closest_regional_office: closest_ro, facility: distances[0] }
  end

  def facility_ids_for_ro(regional_office_id)
    (RegionalOffice::CITIES[regional_office_id][:alternate_locations] ||
      []) << RegionalOffice::CITIES[regional_office_id][:facility_locator_id]
  end

  def get_regional_office_from_facility_id(facility_id)
    return "RO62" if VaDotGovAddressValidatorExceptions.facility_is_san_antonio_satellite_office?(facility_id)

    RegionalOffice::CITIES.find { |_key, regional_office| regional_office[:facility_locator_id] == facility_id }[0]
  end

  def ro_facility_ids_for_state(state_code)
    filter_states = if %w[VA MD].include?(state_code) && !appeal.is_a?(LegacyAppeal)
                      ["DC", state_code]
                    else
                      [state_code]
                    end
    ids = RegionalOffice::CITIES.values.reject do |ro|
      ro[:facility_locator_id].nil? || !filter_states.include?(ro[:state])
    end.pluck(:facility_locator_id)

    ids = VaDotGovAddressValidatorExceptions.include_san_antonio_satellite_office(ids) if state_code == "TX"

    ids
  end

  def valid_states
    @valid_states ||= RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:state)
  end

  def get_state_code(va_dot_gov_address)
    return "DC" if VaDotGovAddressValidatorExceptions.veteran_requested_central_office?(appeal)

    state_code = VaDotGovAddressValidatorExceptions.map_country_code_to_state(va_dot_gov_address)

    fail Caseflow::Error::VaDotGovForeignVeteranError if state_code.nil? || !valid_states.include?(state_code)

    state_code
  end

  def handle_error(error)
    if VaDotGovAddressValidatorExceptions.check_for_philippines_and_maybe_update(appeal, address)
      return { status: STATUSES[:philippines_exception] }
    end

    case error
    when Caseflow::Error::VaDotGovInvalidInputError, Caseflow::Error::VaDotGovAddressCouldNotBeFoundError,
      Caseflow::Error::VaDotGovMultipleAddressError
      admin_action = create_admin_action_for_schedule_hearing_task(
        instructions: "The appellant's address in VBMS does not exist, is incomplete, or is ambiguous.",
        admin_action_type: HearingAdminActionVerifyAddressTask
      )

      { status: STATUSES[:created_admin_action], admin_action: admin_action }
    when Caseflow::Error::VaDotGovForeignVeteranError
      admin_action = create_admin_action_for_schedule_hearing_task(
        instructions: "The appellant's address in VBMS is outside of US territories.",
        admin_action_type: HearingAdminActionForeignVeteranCaseTask
      )

      { status: STATUSES[:created_admin_action], admin_action: admin_action }
    else
      fail error
    end
  end

  def create_admin_action_for_schedule_hearing_task(instructions:, admin_action_type:)
    task = ScheduleHearingTask.open.find_by(appeal: appeal)

    return if task.nil?

    admin_action_type.find_or_create_by(
      appeal: appeal,
      instructions: [instructions],
      assigned_to: HearingsManagement.singleton,
      parent: task
    )
  end
end
