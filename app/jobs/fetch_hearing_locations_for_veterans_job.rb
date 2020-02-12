# frozen_string_literal: true

class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = 500
  def create_schedule_hearing_tasks
    AppealRepository.create_schedule_hearing_tasks
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

  def appeals
    @appeals ||= find_appeals_ready_for_geomatching(LegacyAppeal).first(QUERY_LIMIT / 2) +
                 find_appeals_ready_for_geomatching(Appeal).first(QUERY_LIMIT / 2)
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_schedule_hearing_tasks

    appeals.each do |appeal|
      begin
        appeal.reload # we only selected id and ahl_update_at, reload all columns
        geomatch_result = geomatch(appeal)
        record_geomatched_appeal(appeal.external_id, geomatch_result[:status])
      rescue Caseflow::Error::VaDotGovLimitError
        record_geomatched_appeal(appeal.external_id, "limit_error")
        break
      rescue StandardError => error
        capture_exception(error: error, extra: { appeal_external_id: appeal.external_id })
        record_geomatched_appeal(appeal.external_id, "error")
      end
    end
  end

  def geomatch(appeal)
    geomatch_result = appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls

    case geomatch_result[:status]
    when VaDotGovAddressValidator::STATUSES[:matched_available_hearing_locations],
      VaDotGovAddressValidator::STATUSES[:philippines_exception]
      cancel_admin_actions_for_matched_appeal(appeal)
    when VaDotGovAddressValidator::STATUSES[:created_verify_address_admin_action],
      VaDotGovAddressValidator::STATUSES[:created_foreign_veteran_admin_action]
      create_available_hearing_location_for_errored_appeal(appeal)
    end

    geomatch_result
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
