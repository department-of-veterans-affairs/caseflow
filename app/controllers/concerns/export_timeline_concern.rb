# frozen_string_literal: true

# Used by ExportController to build the data for visualizing a timeline based on
# exported data from SanitizedJsonExporter.

module ExportTimelineConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      record = record.clone
      significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
      end_time = significant_duration ? record["closed_at"] : nil
      {
        id: "#{Task.name}#{record['id']}",
        tableName: Task.table_name,
        status: record["status"],
        content: "#{record['type']}_#{record['id']}",
        start: record["created_at"],
        end: end_time
      }
    end
  end

  # :reek:FeatureEnvy
  def intakes_as_timeline_data
    sje.records_hash[Intake.table_name].map do |record|
      record = record.clone
      significant_duration = record["completed_at"] - record["created_at"] > 120 if record["completed_at"]
      end_time = significant_duration ? record["completed_at"] : nil
      {
        id: "#{record['type']}#{record['id']}",
        tableName: Intake.table_name,
        content: "#{record['type']}_#{record['id']}",
        start: record["created_at"],
        end: end_time
      }
    end
  end
end
