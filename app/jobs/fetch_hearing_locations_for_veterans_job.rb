class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_as :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = 500

  def create_schedule_hearing_tasks
    AppealRepository.create_schedule_hearing_tasks
  end

  def find_appeals_ready_for_geomatching(appeal_type)
    # Appeals that have not had an available_hearing_locations updated in the last week
    # and where the appeal id is in a subquery of ScheduleHearingTasks
    # that are not blocked by an VerifyAddress or ForeignVeteranCase admin action
    appeal_type.left_outer_joins(:available_hearing_locations)
      .where("#{appeal_type.table_name}.id IN (SELECT t.appeal_id FROM tasks t
          LEFT OUTER JOIN tasks admin_actions
          ON t.id = admin_actions.parent_id
          AND admin_actions.type IN ('HearingAdminActionVerifyAddressTask', 'HearingAdminActionForeignVeteranCaseTask')
          AND admin_actions.status NOT IN ('cancelled', 'completed')
          WHERE t.appeal_type = '#{appeal_type.name}'
          AND admin_actions.id IS NULL AND t.type = 'ScheduleHearingTask'
          AND t.status NOT IN ('cancelled', 'completed')
        )")
      .where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.week.ago)
      .limit(QUERY_LIMIT)
  end

  def appeals
    @appeals ||= (find_appeals_ready_for_geomatching(LegacyAppeal) +
                 find_appeals_ready_for_geomatching(Appeal))[0..QUERY_LIMIT]
  end

  def fetch_and_update_ro_for_appeal(appeal, va_dot_gov_address:)
    state_code = get_state_code(va_dot_gov_address, appeal: appeal)
    facility_ids = ro_facility_ids_for_state(state_code)

    distances = VADotGovService.get_distance(ids: facility_ids, lat: va_dot_gov_address[:lat],
                                             long: va_dot_gov_address[:long])
    closest_ro = RegionalOffice::CITIES.find { |_k, v| v[:facility_locator_id] == distances[0][:facility_id] }[0]

    appeal.update(closest_regional_office: closest_ro)

    { closest_regional_office: closest_ro, facility: distances[0] }
  end

  def create_available_locations_for_appeal(appeal, va_dot_gov_address:)
    ro = fetch_and_update_ro_for_appeal(appeal, va_dot_gov_address: va_dot_gov_address)
    facility_ids = facility_ids_for_ro(ro[:closest_regional_office])
    AvailableHearingLocations.where(appeal: appeal).destroy_all

    if facility_ids.length == 1
      create_available_location_for_appeal(appeal, facility: ro[:facility])
    else
      sleep 1
      VADotGovService.get_distance(lat: va_dot_gov_address[:lat], long: va_dot_gov_address[:long], ids: facility_ids)
        .each do |alternate_hearing_location|
          create_available_location_for_appeal(appeal, facility: alternate_hearing_location)
        end
    end
  end

  def perform_once_for(appeal)
    begin
      va_dot_gov_address = appeal.va_dot_gov_address_validator.validate
    rescue Caseflow::Error::VaDotGovLimitError
      return false
    rescue Caseflow::Error::VaDotGovAPIError => error
      handle_error(error, appeal)
      return nil
    end

    begin
      create_available_locations_for_appeal(appeal, va_dot_gov_address: va_dot_gov_address)
    rescue Caseflow::Error::FetchHearingLocationsJobError
      nil
    end
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_schedule_hearing_tasks

    appeals.each do |appeal|
      break if perform_once_for(appeal) == false
    end
  end

  private

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

  def create_available_location_for_appeal(appeal, facility:)
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

  def get_state_code(va_dot_gov_address, appeal:) # rubocop:disable Metrics/CyclomaticComplexity
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
                   handle_error("ForeignVeteranCase", appeal)
                 end

    return state_code if valid_states.include?(state_code)

    handle_error("ForeignVeteranCase", appeal)
  end

  def error_instructions_map
    { "DualAddressError" => "The appellant's address in VBMS is ambiguous.",
      "AddressCouldNotBeFound" => "The appellant's address in VBMS could not be found on a map.",
      "InvalidRequestStreetAddress" => "The appellant's address in VBMS does not exist or is invalid.",
      "ForeignVeteranCase" => "This appellant's address in VBMS is outside of US territories." }
  end

  def get_error_key(error)
    if error == "ForeignVeteranCase"
      "ForeignVeteranCase"
    elsif error.message["messages"] && error.message["messages"][0]
      error.message["messages"][0]["key"]
    end
  end

  def handle_error(error, appeal)
    error_key = get_error_key(error)

    case error_key
    when "DualAddressError", "AddressCouldNotBeFound", "InvalidRequestStreetAddress"
      create_admin_action_for_schedule_hearing_task(
        appeal,
        instructions: error_instructions_map[error_key],
        admin_action_type: HearingAdminActionVerifyAddressTask
      )
    when "ForeignVeteranCase"
      create_admin_action_for_schedule_hearing_task(
        appeal,
        instructions: error_instructions_map[error_key],
        admin_action_type: HearingAdminActionForeignVeteranCaseTask
      )
      fail Caseflow::Error::FetchHearingLocationsJobError, code: 500, message: error_key
    else
      fail error
    end
  end

  def create_admin_action_for_schedule_hearing_task(appeal, instructions:, admin_action_type:)
    task = ScheduleHearingTask.find_by(appeal: appeal)

    return if task.nil?

    admin_action_type.create!(
      appeal: appeal,
      instructions: [instructions],
      assigned_to: HearingsManagement.singleton,
      parent: task
    )
  end
end
