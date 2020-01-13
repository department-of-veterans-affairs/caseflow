# frozen_string_literal: true

class AmaAssignHearingsTab < QueueTab
  attr_accessor :regional_office_key

  def self.tab_name
    Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME
  end

  def tasks
    # Sorting by docket number within each category of appeal: AOD and normal.
    ScheduleHearingTask
      .includes(*task_includes)
      .active
      .where(appeal_type: Appeal.name)
      .joins(CachedAppeal.left_join_from_tasks_clause)
      .where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)
      .order("cached_appeal_attributes.is_aod DESC, cached_appeal_attributes.docket_number ASC")
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
