# frozen_string_literal: true

class NationalHearingQueueEntry < CaseflowRecord
  def self.refresh
    Scenic.database.refresh_materialized_view(
      "national_hearing_queue_entries",
      concurrently: false,
      cascade: false
    )
  end
end
