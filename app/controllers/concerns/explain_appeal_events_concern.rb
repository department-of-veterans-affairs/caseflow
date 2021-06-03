# frozen_string_literal: true

# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  def tasks_as_event_data
    object_type = Task.name.downcase
    sje.records_hash[Task.table_name].map do |record|
      significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
      ExplainController::AppealEventData.new(
        record["created_at"], object_type, "#{record['type']}_#{record['id']}", "created"
      ).tap do |event|
        event.comment = "created task"
        event.relevant_data = {
          duration: significant_duration ? record["closed_at"] - record["created_at"] : nil
        }
        event.details = record
      end
    end.flatten.sort_by(&:timestamp)
  end
end
