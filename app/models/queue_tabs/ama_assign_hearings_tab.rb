# frozen_string_literal: true

class AmaAssignHearingsTab < QueueTab
  def self.tab_name
    Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME
  end

  def tasks
    ScheduleHearingTask.includes(*task_includes).active.where(appeal_type: "Appeal")
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
