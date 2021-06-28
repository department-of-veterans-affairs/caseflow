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

  # integer values correspond with those defined in function `groupEventItems` of explain-appeal.js
  EVENT_GROUPS = {
    "phase" => 0,
    Task.table_name => 1,
    Intake.table_name => 2
  }.freeze

  BACKGROUND_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask].freeze

  # :reek:FeatureEnvy
  # :reek:Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{Task.name}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Task.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["created_at"]
        clone_record["taskType"] = record["type"]

        if BACKGROUND_TASK_TYPES.include?(record["type"])
          clone_record["type"] = "background"
          clone_record["group"] = nil # so that background is visible in all groups
          clone_record["end"] ||= Time.zone.today # needs to be set for 'background' types
        else
          significant_duration = record["closed_at"] - record["created_at"] > 60 if record["closed_at"]
          clone_record["type"] = significant_duration ? "range" : "point"
          clone_record["group"] = EVENT_GROUPS[Task.table_name]
          clone_record["end"] = significant_duration ? record["closed_at"] : nil
        end

        # for visualization
        # clone_record["group"] = Task.table_name
        clone_record["title"] = "<pre style='font-size:0.84em'><code>#{JSON.pretty_generate(clone_record)}</code></pre>"
        clone_record["className"] = "#{record['type']} task_#{record['status']}"
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # :reek:FeatureEnvy
  def intakes_as_timeline_data
    sje.records_hash[Intake.table_name].map do |record|
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{record['type']}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Intake.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["start"] = record["started_at"]
        clone_record["end"] = record["completed_at"]
        clone_record["intakeType"] = record["type"]

        # clear these values to prevent conflict the Timeline Item's fields
        significant_duration = record["completed_at"] - record["started_at"] > 120 if record["completed_at"]
        clone_record["type"] = significant_duration ? "range" : "point"
        clone_record["group"] = EVENT_GROUPS[Intake.table_name]
      end
    end
  end
end
