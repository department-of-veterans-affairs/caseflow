# frozen_string_literal: true

# Used by ExportController to build the data for visualizing a timeline based on
# exported data from SanitizedJsonExporter.

module ExportTimelineConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{Task.name}#{record['id']}"
        clone_record["tableName"] = Task.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["created_at"]
        clone_record["end"] = significant_duration ? record["closed_at"] : nil
        clone_record["taskType"] = record["type"]

        # clear these values to prevent conflict the Timeline Item's fields
        clone_record["type"] = nil
      end
    end
  end

  # :reek:FeatureEnvy
  def intakes_as_timeline_data
    sje.records_hash[Intake.table_name].map do |record|
      significant_duration = record["completed_at"] - record["created_at"] > 120 if record["completed_at"]
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{record['type']}#{record['id']}"
        clone_record["tableName"] = Intake.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["created_at"]
        clone_record["end"] = significant_duration ? record["completed_at"] : nil
        clone_record["intakeType"] = record["type"]

        # clear these values to prevent conflict the Timeline Item's fields
        clone_record["type"] = nil
      end
    end
  end
end
