# frozen_string_literal: true

# Used by ExplainController to build the data for visualizing a timeline based on
# exported data from SanitizedJsonExporter.

module ExplainTimelineConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def timeline_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    tasks_as_timeline_data + intakes_as_timeline_data
  end

  EVENT_GROUPS = {

  }

  BACKGROUND_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask].freeze

  # :reek:FeatureEnvy
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{Task.name}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Task.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["created_at"]
        clone_record["end"] = significant_duration ? record["closed_at"] : nil
        clone_record["taskType"] = record["type"]

        # clear these values to prevent conflict the Timeline Item's fields
        # clone_record["type"] = "point" unless significant_duration
        if BACKGROUND_TASK_TYPES.include?(record["type"])
          clone_record["type"] = "background"
          clone_record["group"] = nil # so that background is visible in all groups
          clone_record["end"] ||= record["closed_at"] || Date.today # needs to be set for 'background' types
        else
          clone_record["type"] = nil
          clone_record["group"] = 1
        end

        # for visualization
        # clone_record["group"] = Task.table_name
        clone_record["title"] = "<pre style='font-size:0.84em'><code>#{JSON.pretty_generate(clone_record)}</code></pre>"
        clone_record["className"] = "#{record['type']} task_#{record['status']}"
      end
    end
  end

  # :reek:FeatureEnvy
  def intakes_as_timeline_data
    sje.records_hash[Intake.table_name].map do |record|
      significant_duration = record["completed_at"] - record["started_at"] > 120 if record["completed_at"]
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{record['type']}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Intake.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["started_at"]
        clone_record["end"] = significant_duration ? record["completed_at"] : nil
        clone_record["intakeType"] = record["type"]

        # clear these values to prevent conflict the Timeline Item's fields
        clone_record["type"] = nil
        clone_record["group"] = 2
      end
    end
  end
end
