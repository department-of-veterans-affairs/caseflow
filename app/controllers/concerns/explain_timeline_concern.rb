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

  BACKGROUND_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask].freeze

  # clone_record["type"] is one of the vis-timeline item types: range, box, point, background
  # clone_record["title"] is displayed as the tooltip
  # See https://visjs.github.io/vis-timeline/docs/timeline/#items

  # clone_record["group"] corresponds with a group defined in function `groupEventItems` of explain-appeal.js
  # See https://visjs.github.io/vis-timeline/docs/timeline/#groups

  # rubocop:disable Metrics/MethodLength
  # :reek:FeatureEnvy
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
          clone_record["group"] = nil # so that background is visible in all groups
          clone_record["type"] = "background"
          clone_record["end"] ||= Time.zone.today # needs to be set for 'background' types
        else
          clone_record["group"] = (clone_record["status"] == "cancelled") ? "cancelled_tasks" : Task.table_name
          significant_duration = record["closed_at"] - record["created_at"] > 60 if record["closed_at"]
          clone_record["type"] = significant_duration ? "range" : "point"
          clone_record["end"] = significant_duration ? record["closed_at"] : nil
        end

        # for visualization
        clone_record["title"] = "<pre><code style='font-size:0.7em'>#{JSON.pretty_generate(clone_record)}</code></pre>"
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
        clone_record["intakeType"] = record["type"]

        clone_record["group"] = Intake.table_name
        significant_duration = record["completed_at"] - record["started_at"] > 360 if record["completed_at"]
        clone_record["type"] = significant_duration ? "range" : nil
        clone_record["end"] = significant_duration ? record["completed_at"] : nil

        # for visualization
        clone_record["title"] = "<pre><code style='font-size:0.7em'>#{JSON.pretty_generate(clone_record)}</code></pre>"
        clone_record["className"] = record["type"]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
