# frozen_string_literal: true

class GeomatchService
  def initialize(appeal:)
    @appeal = appeal
  end

  # Performs geomatching for an appeal.
  #
  # @param appeal  [Appeal, Legacy] the appeal to geomatch
  #
  # @raise      [Caseflow::Error::VaDotGovLimitError]
  #   Re-raises limit error for caller to handle.
  # @raise      [StandardError]
  #   Re-raises standard error for caller to handle.
  def geomatch
    begin
      geomatch_result = appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
      handle_geocode_status(geomatch_result)
      record_geomatched_appeal(geomatch_result[:status])
    rescue Caseflow::Error::VaDotGovLimitError
      record_geomatched_appeal("limit_error")
      raise
    rescue StandardError
      record_geomatched_appeal("error")
      raise
    end
  end

  private

  attr_reader :appeal

  # Handles the status from the VaDotGovAddressValidator.
  #
  # @param geomatch_result  [Hash] The result from geocoding.
  def handle_geocode_status(geomatch_result)
    case geomatch_result[:status]
    when VaDotGovAddressValidator::STATUSES[:matched_available_hearing_locations],
      VaDotGovAddressValidator::STATUSES[:philippines_exception]
      cancel_admin_actions_for_matched_appeal
    when VaDotGovAddressValidator::STATUSES[:created_verify_address_admin_action],
      VaDotGovAddressValidator::STATUSES[:created_foreign_veteran_admin_action]
      create_available_hearing_location_for_errored_appeal
    end
  end

  def cancel_admin_actions_for_matched_appeal
    tasks_to_cancel = Task.open.where(
      type: %w[HearingAdminActionVerifyAddressTask HearingAdminActionForeignVeteranCaseTask],
      appeal: appeal
    )

    tasks_to_cancel.each { |task| task.update(status: Constants.TASK_STATUSES.cancelled) }
  end

  def create_available_hearing_location_for_errored_appeal
    # we need a way to flag that we've seen this appeal before/recently
    if appeal.available_hearing_locations.count == 0
      AvailableHearingLocations.create(
        appeal: appeal,
        veteran_file_number: appeal.veteran_file_number || ""
      )
    else
      appeal.available_hearing_locations.each(&:touch)
    end
  end

  def record_geomatched_appeal(status)
    DataDogService.increment_counter(
      app_name: RequestStore[:application],
      metric_group: "job",
      metric_name: "geomatched_appeals",
      attrs: {
        status: status,
        appeal_external_id: appeal.external_id,
        hearing_request_type: appeal.current_hearing_request_type
      }
    )
  end
end
