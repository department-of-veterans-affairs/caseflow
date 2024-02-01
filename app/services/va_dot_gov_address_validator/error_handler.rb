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
    elsif foreign_veteran_errors.any? { |klass| error.instance_of?(klass) }
      appeal.va_dot_gov_address_validator.assign_ro_and_update_ahls("RO11")

      :foreign_veteran_exception
    elsif verify_address_errors.any? { |klass| error.instance_of?(klass) }
      create_admin_action_for_schedule_hearing_task(
        instructions: "The appellant's address in VBMS does not exist, is incomplete, or is ambiguous.",
        admin_action_type: HearingAdminActionVerifyAddressTask
      )

      :created_verify_address_admin_action
    else
      # :nocov:
      raise error # rubocop:disable Style/SignalException
      # :nocov:
    end
  end

  private

  def verify_address_errors
    [Caseflow::Error::VaDotGovInvalidInputError, Caseflow::Error::VaDotGovAddressCouldNotBeFoundError,
     Caseflow::Error::VaDotGovMultipleAddressError, Caseflow::Error::VaDotGovNullAddressError]
  end

  def foreign_veteran_errors
    [Caseflow::Error::VaDotGovForeignVeteranError]
  end

  def check_for_philippines_and_maybe_update
    if appellant_address.present? && "Philippines".casecmp(appellant_address.country) == 0
      appeal.va_dot_gov_address_validator.assign_ro_and_update_ahls("RO58")

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
