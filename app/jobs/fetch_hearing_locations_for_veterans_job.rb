# frozen_string_literal: true

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
          WHERE t.appeal_type = ?
          AND admin_actions.id IS NULL AND t.type = 'ScheduleHearingTask'
          AND t.status NOT IN ('cancelled', 'completed')
        )", appeal_type.name)
      .order("available_hearing_locations.updated_at nulls first")
      .limit(QUERY_LIMIT)
  end

  def appeals
    @appeals ||= find_appeals_ready_for_geomatching(LegacyAppeal)[0..(QUERY_LIMIT / 2).to_int] +
                 find_appeals_ready_for_geomatching(Appeal)[0..(QUERY_LIMIT / 2).to_int]
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_schedule_hearing_tasks

    appeals.each do |appeal|
      begin
        geomatch_result = appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
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
