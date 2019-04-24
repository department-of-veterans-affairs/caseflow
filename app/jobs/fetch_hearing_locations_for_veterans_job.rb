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
          AND admin_actions.status NOT IN ('cancelled', 'completed')
          WHERE t.appeal_type = ?
          AND admin_actions.id IS NULL AND t.type = 'ScheduleHearingTask'
          AND t.status NOT IN ('cancelled', 'completed')
        )", appeal_type.name)
      .where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.week.ago)
      .limit(QUERY_LIMIT)
  end

  def appeals
    @appeals ||= (find_appeals_ready_for_geomatching(LegacyAppeal) +
                 find_appeals_ready_for_geomatching(Appeal))[0..QUERY_LIMIT]
  end

  def perform
    RequestStore.store[:current_user] = User.system_user
    create_schedule_hearing_tasks

    appeals.each do |appeal|
      begin
        appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
      rescue Caseflow::Error::VaDotGovLimitError
        break
      end
    end
  end
end
