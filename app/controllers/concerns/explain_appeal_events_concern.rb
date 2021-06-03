# frozen_string_literal: true

# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def tasks_as_event_data
    sje.records_hash[Task.table_name].map do |record|
      [
        task_created_event(record),
        task_closed_event(record)
      ]
    end.flatten.compact.sort_by(&:timestamp)
  end

  # :reek:UtilityFunction
  def task_created_event(record)
    significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
    ExplainController::AppealEventData.new(
      record["created_at"], Task.name.downcase, "#{record['type']}_#{record['id']}", "created"
    ).tap do |event|
      event.comment = "created task"
      event.relevant_data = {
        appeal_id: record["appeal_id"],
        duration: significant_duration ? record["closed_at"] - record["created_at"] : nil
      }
      event.details = record
    end
  end

  # :reek:UtilityFunction
  def task_closed_event(record)
    return nil unless record["closed_at"]

    significant_duration = record["closed_at"] - record["created_at"] > 120
    ExplainController::AppealEventData.new(
      record["closed_at"], Task.name.downcase, "#{record['type']}_#{record['id']}", "closed"
    ).tap do |event|
      event.comment = "closed task"
      event.relevant_data = {
        status: record["status"],
        appeal_id: record["appeal_id"],
        duration: significant_duration ? record["closed_at"] - record["created_at"] : nil
      }
      event.details = record
    end
  end
end
