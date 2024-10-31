# frozen_string_literal: true

class NationalHearingQueueEntry < CaseflowRecord
  belongs_to :appeal, polymorphic: true
  belongs_to :task, class_name: "ScheduleHearingTask"

  def self.refresh
    Scenic.database.refresh_materialized_view(
      "national_hearing_queue_entries",
      concurrently: false,
      cascade: false
    )
  end
end
