# frozen_string_literal: true

class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = 650
  QUERY_TRAVEL_BOARD_LIMIT = 100
  JOB_DURATION = 1.hour

  def create_schedule_hearing_tasks
    HearingTaskTreeInitializer.create_schedule_hearing_tasks
  end

  def find_appeals_ready_for_geomatching(appeal_type, select_fields: [])
    appeal_ids = ScheduleHearingTask.open.where(
      appeal_type: appeal_type.name
    ).pluck(:appeal_id)

    appeal_type.left_outer_joins(:available_hearing_locations)
      .select(:id, *select_fields)
      .select("MIN(available_hearing_locations.updated_at) as ahl_updated_at")
      .where(id: appeal_ids)
      .group(:id)
      .order("ahl_updated_at nulls first")
  end

  # Gets appeals that are ready for geomatching.
  #
  # @return     [Array<Appeal, LegacyAppeal>]
  #   An array of appeals that are ready for geomatching, bounded by the `QUERY_LIMIT`
  #   and `QUERY_TRAVEL_BOARD_LIMIT`.
  def appeals
    @appeals ||= begin
                   legacy_appeals = find_appeals_ready_for_geomatching(
                     LegacyAppeal,
                     select_fields: [:vacols_id]
                   ).first(QUERY_LIMIT / 2)
                   ama_appeals = find_appeals_ready_for_geomatching(Appeal).first(QUERY_LIMIT / 2)
                   travel_board_appeals = find_travel_board_appeals_ready_for_geomatching(
                     legacy_appeals.map(&:vacols_id)
                   ).first(QUERY_TRAVEL_BOARD_LIMIT)

                   legacy_appeals + ama_appeals + travel_board_appeals
                 end
  end

  NONACTIONABLE_ERRORS = [Caseflow::Error::VaDotGovMissingFacilityError].freeze

  # rubocop:disable Metrics/MethodLength
  def perform
    setup_job
    current_appeal = 0

    loop do
      remaining_appeals = appeals[current_appeal..-1]

      break if remaining_appeals.empty? || job_running_past_expected_end_time?

      remaining_appeals.each do |appeal|
        break if job_running_past_expected_end_time?

        begin
          # we only selected id and ahl_update_at, reload all columns
          GeomatchService.new(appeal: appeal.reload).geomatch

          current_appeal += 1
        rescue Caseflow::Error::VaDotGovLimitError
          Rails.logger.error("VA.gov returned a rate limit error")

          sleep_before_retry_on_limit_error

          break
        rescue StandardError => error
          actionable = NONACTIONABLE_ERRORS.include?(error.class)
          capture_exception(error: error, extra: { appeal_external_id: appeal.external_id, actionable: actionable })

          # For unknown errors, we capture the exeception in Sentry. This error could represent
          # a broad range of things, so we just skip geomatching for the appeal, and expect
          # that a developer looks into it.
          current_appeal += 1
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_accessor :job_expected_end_time

  def setup_job
    RequestStore.store[:current_user] = User.system_user

    @job_expected_end_time = Time.zone.now + JOB_DURATION

    create_schedule_hearing_tasks
  end

  # Returns whether or not the job is running beyond the expected end time.
  def job_running_past_expected_end_time?
    Time.zone.now > job_expected_end_time
  end

  # Pauses execution based on an error received from VA.gov.
  #
  # @note This is its own method so that it can be stubbed by the test suite.
  def sleep_before_retry_on_limit_error
    sleep 15
  end

  # Finds all travel board hearings that are ready for geomatching.
  #
  # @param exclude_ids  [Array<String>] VACOLS ids of VACOLS cases to ignore
  #
  # @return             [Array<LegacyAppeal]
  #   An array of travel board appeals that are ready for geomatching
  def find_travel_board_appeals_ready_for_geomatching(exclude_ids)
    VACOLS::Case
      .where(
        # Travle Board Hearing Request
        bfhr: VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value],
        # Current Location
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        # Video Hearing Request Indicator
        bfdocind: nil,
        # Datetime of Decision
        bfddec: nil
      )
      .where.not(bfkey: exclude_ids)
      .map do |vacols_case|
        AppealRepository.build_appeal(vacols_case, true)
      end
  end
end
