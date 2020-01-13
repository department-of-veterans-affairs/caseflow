# frozen_string_literal: true

class LegacyAssignHearingsTab < QueueTab
  attr_accessor :regional_office_key

  def self.tab_name
    Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME
  end

  def tasks
    tasks = ScheduleHearingTask
      .includes(*task_includes)
      .active
      .where(appeal_type: LegacyAppeal.name)
      .joins(<<-SQL)
        INNER JOIN legacy_appeals
        ON legacy_appeals.id = appeal_id 
        AND tasks.appeal_type = 'LegacyAppeal'
      SQL

    central_office_ids = VACOLS::Case.where(bfhr: 1, bfcurloc: "CASEFLOW").pluck(:bfkey)

    # For legacy appeals, we need to only provide a central office hearing if they explicitly
    # chopse one. Likewise, we can't use DC if it's the closest regional office unless they
    # choose a central office hearing.
    if regional_office_key == "C"
      tasks.where("legacy_appeals.vacols_id IN (?)", central_office_ids)
    else
      tasks_by_ro = tasks.where("legacy_appeals.closest_regional_office = ?", regional_office_key)

      # For context: https://github.com/rails/rails/issues/778#issuecomment-432603568
      if central_office_ids.empty?
        tasks_by_ro
      else
        tasks_by_ro.where("legacy_appeals.vacols_id NOT IN (?)", central_office_ids)
      end
    end
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
      Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN
    ]
  end
end
