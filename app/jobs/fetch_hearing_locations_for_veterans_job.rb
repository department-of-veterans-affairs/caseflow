# frozen_string_literal: true

class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = 750
  JOB_DURATION = 1.hour

  def create_schedule_hearing_tasks
    HearingTaskTreeInitializer.create_schedule_hearing_tasks
  end

  def find_appeals_ready_for_geomatching(appeal_type)
    appeal_ids = ScheduleHearingTask.open.where(
      appeal_type: appeal_type.name
    ).pluck(:appeal_id)

    appeal_type.left_outer_joins(:available_hearing_locations)
      .select(:id)
      .select("MIN(available_hearing_locations.updated_at) as ahl_updated_at")
      .where(id: appeal_ids)
      .group(:id)
      .order("ahl_updated_at nulls first")
  end

  # Gets appeals that are ready for geomatching.
  #
  # @return     [Array<Appeal, LegacyAppeal>]
  #   An array of appeals that are ready for geomatching, bounded by the `QUERY_LIMIT`.
  def appeals
    @appeals ||= find_appeals_ready_for_geomatching(LegacyAppeal).first(QUERY_LIMIT / 2) +
                 find_appeals_ready_for_geomatching(Appeal).first(QUERY_LIMIT / 2)
  end

  def perform
    RequestStore.store[:current_user] = User.system_user

    @job_expected_end_time = Time.zone.now + JOB_DURATION
    current_appeal = 0

    create_schedule_hearing_tasks

    loop do
      remaining_appeals = appeals[current_appeal..-1]

      break if remaining_appeals.empty? || job_running_past_expected_end_time?

      remaining_appeals.each do |appeal|
        break if job_running_past_expected_end_time?

        begin
          geomatch(appeal)

          current_appeal += 1
        rescue Caseflow::Error::VaDotGovLimitError => error
          sleep_before_retry_on_limit_error(error)

          break
        rescue StandardError
          # For unknown errors, we capture the exeception in Sentry. This error could represent
          # a broad range of things, so we just skip geomatching for the appeal, and expect
          # that a developer looks into it.
          current_appeal += 1
        end
      end
    end
  end

  private

  attr_accessor :job_expected_end_time

  # Returns whether or not the job is running beyond the expected end time.
  def job_running_past_expected_end_time?
    Time.zone.now > job_expected_end_time
  end

  # Pauses execution based on an error received from VA.gov.
  #
  # @note This is its own method so that it can be stubbed by the test suite.
  #
  # @param limit_error  [Caseflow::Error::VaDotGovLimitError] instance of an error received from VA.gov
  def sleep_before_retry_on_limit_error(limit_error)
    sleep_time_in_minutes = limit_error.remaining_time || limit_error.rate_limit || 5
    sleep sleep_time_in_minutes * 60
  end

  # Performs geomatching for an appeal.
  #
  # @param appeal  [Appeal, Legacy] the appeal to geomatch
  #
  # @raise      [Caseflow::Error::VaDotGovLimitError]
  #   Re-raises limit error for caller to handle.
  # @raise      [StandardError]
  #   Re-raises standard error for caller to handle.
  def geomatch(appeal)
    appeal.reload # we only selected id and ahl_update_at, reload all columns

    begin
      geomatch_result = appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
      handle_geocode_status(appeal, geomatch_result)
      record_geomatched_appeal(appeal.external_id, geomatch_result[:status])
    rescue Caseflow::Error::VaDotGovLimitError => error
      Rails.logger.error("VA.gov returned a rate limit error")
      Rails.logger.error(
        "Remaining time = #{error.remaining_time}, rate limit = #{error.rate_limit}"
      )
      record_geomatched_appeal(appeal.external_id, "limit_error")
      raise
    rescue StandardError => error
      capture_exception(error: error, extra: { appeal_external_id: appeal.external_id })
      record_geomatched_appeal(appeal.external_id, "error")
      raise
    end
  end

  # Handles the status from the VaDotGovAddressValidator.
  #
  # @param geomatch_result  [Hash] The result from geocoding.
  def handle_geocode_status(appeal, geomatch_result)
    case geomatch_result[:status]
    when VaDotGovAddressValidator::STATUSES[:matched_available_hearing_locations],
      VaDotGovAddressValidator::STATUSES[:philippines_exception]
      cancel_admin_actions_for_matched_appeal(appeal)
    when VaDotGovAddressValidator::STATUSES[:created_verify_address_admin_action],
      VaDotGovAddressValidator::STATUSES[:created_foreign_veteran_admin_action]
      create_available_hearing_location_for_errored_appeal(appeal)
    end
  end

  def cancel_admin_actions_for_matched_appeal(appeal)
    tasks_to_cancel = Task.open.where(
      type: %w[HearingAdminActionVerifyAddressTask HearingAdminActionForeignVeteranCaseTask],
      appeal: appeal
    )

    tasks_to_cancel.each { |task| task.update(status: Constants.TASK_STATUSES.cancelled) }
  end

  def create_available_hearing_location_for_errored_appeal(appeal)
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

  def record_geomatched_appeal(appeal_external_id, status)
    DataDogService.increment_counter(
      app_name: RequestStore[:application],
      metric_group: "job",
      metric_name: "geomatched_appeals",
      attrs: {
        status: status,
        appeal_external_id: appeal_external_id
      }
    )
  end
end
