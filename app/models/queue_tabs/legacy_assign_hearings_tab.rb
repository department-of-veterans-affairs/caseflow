# frozen_string_literal: true

class LegacyAssignHearingsTab < QueueTab
  def self.tab_name
    Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME
  end

  def tasks
    ScheduleHearingTask.includes(*task_includes).active.where(appeal_type: "LegacyAppeal")
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
      Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN
    ].compact
  end
end
