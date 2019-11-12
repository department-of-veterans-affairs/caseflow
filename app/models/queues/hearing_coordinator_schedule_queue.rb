# frozen_string_literal: true

# This class is intended to mimic the behavior of queues
# for Hearing Coordinators

# Hearing coordinators do not work ScheduleHearingTasks
# from organization or personal queues
# Instead, they work a the assign/hearings page which retrieves
# queries tasks in the same way as Queues

class HearingCoordinatorScheduleQueue < GenericQueue
  attr_accessor :user, :regional_office

  def initialize(user, regional_office:)
    @user = user
    @regional_office = regional_office
  end

  def tasks
    # Get all tasks associated with AMA appeals and the regional_office
    incomplete_tasks = ScheduleHearingTask.where(
      "status = ? OR status = ?",
      Constants.TASK_STATUSES.assigned.to_sym,
      Constants.TASK_STATUSES.in_progress.to_sym
    ).includes(*task_includes)

    appeal_tasks = incomplete_tasks.joins(
      "INNER JOIN appeals ON appeals.id = appeal_id AND tasks.appeal_type = 'Appeal'"
    ).where("appeals.closest_regional_office = ?", regional_office)

    appeal_tasks + legacy_appeal_tasks(regional_office, incomplete_tasks)
  end

  private

  def task_includes
    super << { attorney_case_reviews: [:attorney] }
  end

  def legacy_appeal_tasks(regional_office, incomplete_tasks)
    joined_incomplete_tasks = incomplete_tasks.joins(
      "INNER JOIN legacy_appeals ON legacy_appeals.id = appeal_id AND tasks.appeal_type = 'LegacyAppeal'"
    )

    central_office_ids = VACOLS::Case.where(bfhr: 1, bfcurloc: "CASEFLOW").pluck(:bfkey)
    central_office_legacy_appeal_ids = LegacyAppeal.where(vacols_id: central_office_ids).pluck(:id)

    # For legacy appeals, we need to only provide a central office hearing if they explicitly
    # chose one. Likewise, we can't use DC if it's the closest regional office unless they
    # chose a central office hearing.
    if regional_office == "C"
      joined_incomplete_tasks.where("legacy_appeals.id IN (?)", central_office_legacy_appeal_ids)
    else
      tasks_by_ro = joined_incomplete_tasks.where("legacy_appeals.closest_regional_office = ?", regional_office)

      # For context: https://github.com/rails/rails/issues/778#issuecomment-432603568
      if central_office_legacy_appeal_ids.empty?
        tasks_by_ro
      else
        tasks_by_ro.where("legacy_appeals.id NOT IN (?)", central_office_legacy_appeal_ids)
      end
    end
  end
end
