# frozen_string_literal: true

class VaDotGovAddressValidator::ErrorHandler
  attr_reader :appeal, :appellant_address

  def initialize(appeal:, appellant_address:)
    @appeal = appeal
    @appellant_address = appellant_address
  end

  def handle(error)
    if check_for_philippines_and_maybe_update
      :philippines_exception
    elsif verify_address_errors.any? { |klass| error == klass }
      create_admin_action_for_schedule_hearing_task(
        instructions: "The appellant's address in VBMS does not exist, is incomplete, or is ambiguous.",
        admin_action_type: HearingAdminActionVerifyAddressTask
      )

      :created_verify_address_admin_action
    elsif foreign_veteran_errors.any? { |klass| error == klass }
      create_admin_action_for_schedule_hearing_task(
        instructions: "The appellant's address in VBMS is outside of US territories.",
        admin_action_type: HearingAdminActionForeignVeteranCaseTask
      )

      :created_foreign_veteran_admin_action
    else
      fail error, code: 500, message: "VA Dot Gov error"
    end
  end

  private

  def verify_address_errors
    [Caseflow::Error::VaDotGovInvalidInputError, Caseflow::Error::VaDotGovAddressCouldNotBeFoundError,
     Caseflow::Error::VaDotGovMultipleAddressError]
  end

  def foreign_veteran_errors
    [Caseflow::Error::VaDotGovForeignVeteranError]
  end

  def check_for_philippines_and_maybe_update
    return false if appellant_address.nil?

    if "Philippines".casecmp(appellant_address[:country]) == 0
      appeal.update(closest_regional_office: "RO58")
      facility = VADotGovService.get_facility_data(ids: ["vba_358"]).first
      appeal.va_dot_gov_address_validator.create_available_hearing_location(facility: facility)

      return true
    end

    false
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
