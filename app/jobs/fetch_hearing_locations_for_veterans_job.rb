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
      appeal.va_dot_gov_address_validator.create_available_hearing_locations(va_dot_gov_address: va_dot_gov_address)
    rescue Caseflow::Error::VaDotGovValidatorError => error
      handle_error(error, appeal)
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

  def error_instructions_map
    { "DualAddressError" => "The appellant's address in VBMS is ambiguous.",
      "AddressCouldNotBeFound" => "The appellant's address in VBMS could not be found on a map.",
      "InvalidRequestStreetAddress" => "The appellant's address in VBMS does not exist or is invalid.",
      "ForeignVeteranCase" => "This appellant's address in VBMS is outside of US territories." }
  end

  def get_error_key(error)
    if error.message.is_a?(String)
      error.message
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
