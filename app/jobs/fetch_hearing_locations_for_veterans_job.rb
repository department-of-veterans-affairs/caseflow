# frozen_string_literal: true

class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_as :low_priority
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
      .where(id: appeal_ids)
      .order("available_hearing_locations.updated_at nulls first")
      .limit(QUERY_LIMIT)
  end

  def appeals
    @appeals ||= find_appeals_ready_for_geomatching(LegacyAppeal).first(QUERY_LIMIT / 2) +
                 find_appeals_ready_for_geomatching(Appeal).first(QUERY_LIMIT / 2)
  end

  def geomatch(appeal)
    geomatch_result = appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
    if geomatch_result[:status] == VaDotGovAddressValidator::STATUSES[:matched_available_hearing_locations]
      cancel_admin_actions_for_matched_appeal(appeal)
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

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_schedule_hearing_tasks

    appeals.each do |appeal|
      begin
        geomatch_result = geomatch(appeal)
        record_geomatched_appeal(appeal.external_id, geomatch_result[:status])
        sleep 1
      rescue Caseflow::Error::VaDotGovLimitError
        record_geomatched_appeal(appeal.external_id, "limit_error")
        break
      rescue StandardError => error
        capture_exception(error: error, extra: { appeal_external_id: appeal.external_id })
        record_geomatched_appeal(appeal.external_id, "error")
      end
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
