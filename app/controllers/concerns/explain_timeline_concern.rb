# frozen_string_literal: true

# Used by ExplainController to build the data for visualizing a timeline based on
# exported data from SanitizedJsonExporter.

module ExplainTimelineConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def timeline_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    tasks_timeline_data + intake_timeline_data + hearings_timeline_data
  end

  BACKGROUND_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask BvaDispatchTask].freeze

  # clone_record["type"] is one of the vis-timeline item types: range, box, point, background
  # clone_record["title"] is displayed as the tooltip
  # See https://visjs.github.io/vis-timeline/docs/timeline/#items

  # clone_record["group"] corresponds with a group defined in function `groupEventItems` of explain-appeal.js
  # See https://visjs.github.io/vis-timeline/docs/timeline/#groups

  # rubocop:disable Metrics/MethodLength
  # :reek:FeatureEnvy
  # rubocop:disable Metrics/AbcSize
  def tasks_timeline_data
    exported_records(Task).map do |record|
      if BACKGROUND_TASK_TYPES.include?(record["type"])
        record.clone.tap do |clone_record|
          clone_record["id"] = "#{Task.name}#{record['id']}_bkgd"
          clone_record["record_id"] = record["id"]
          clone_record["tableName"] = Task.table_name
          clone_record["taskType"] = record["type"]
          clone_record["start"] = record["created_at"]
          clone_record["end"] = Time.zone.now if record["closed_at"].nil?

          clone_record["group"] = nil
          clone_record["type"] = "background"
          clone_record["end"] ||= record["closed_at"] # needs to be set for 'background' types

          clone_record["content"] = ""
          clone_record["title"] = "<pre><code style='font-size:0.7em; white-space: pre-line; width: 100px;'>#{JSON.pretty_generate(clone_record)}</code></pre>"
          clone_record["className"] = "#{record['type']} task_#{record['status']}"
          end
      end
    end.compact +
    exported_records(Task).map do |record|
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{Task.name}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Task.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["taskType"] = record["type"]
        clone_record["start"] = record["created_at"]
        clone_record["end"] = Time.zone.now if record["closed_at"].nil?
        clone_record["type"] = "range"

        if false && BACKGROUND_TASK_TYPES.include?(record["type"]) # TODO: make this configurable
          clone_record["group"] = nil # so that background is visible in all groups
          clone_record["type"] = "background"
          clone_record["end"] ||= record["closed_at"] # needs to be set for 'background' types
        else
          clone_record["group"] = (clone_record["status"] == "cancelled") ? "cancelled_tasks" : Task.table_name
          if clone_record["end"].nil?
            significant_duration = record["closed_at"] - record["created_at"] > 60 if record["closed_at"]
            clone_record["type"] = significant_duration ? "range" : "point"
            clone_record["end"] = significant_duration ? record["closed_at"] : nil
          end

          if BACKGROUND_TASK_TYPES.include?(record["type"])
            clone_record["group"] = "phase"
          end
        end

        TimelineEventData.new(Task, record).tap do |event|
          if BACKGROUND_TASK_TYPES.include?(record["type"])
            event.group = "phase"
          else
            event.group = (record["status"] == "cancelled") ? "cancelled_tasks" : Task.table_name
          end          

          significant_duration = record["closed_at"] - record["created_at"] > 60 if record["closed_at"]
          if !significant_duration
            event.type = "point"
            event.end = nil
          end

          # for visualization
          event.className += " task_#{record['status']}"
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # :reek:TooManyInstanceVariables
  class TimelineEventData
    attr_reader :id, :recordId
    attr_accessor :start, :end, :group, :type, :className
  
    def initialize(klass, record, 
                   start_time: record["created_at"], 
                   end_time: record["closed_at"],
                   renderType: "range",
                   recordType: record["type"], 
                   label: "#{record['type']}_#{record['id']}",
                   tooltip: "<pre><code style='font-size:0.7em'>#{JSON.pretty_generate(record)}</code></pre>")
      @id = "#{klass.name}#{record['id']}"
      @recordId = record["id"]
      @tableName = klass.table_name
      @content = label
      @recordType = recordType
      @start = start_time
      @end = Time.zone.now if end_time.nil?
      @type = renderType

      # for visualization
      @title = tooltip
      @className = record['type']
    end
  end

  # :reek:FeatureEnvy
  def intake_timeline_data
    exported_records(Intake).map do |record|
      record.clone.tap do |clone_record|
        clone_record["id"] = "#{record['type']}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Intake.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["intakeType"] = record["type"]
        clone_record["start"] = record["started_at"]
        clone_record["end"] = Time.zone.now if record["completed_at"].nil?
        clone_record["type"] = "range" 

        clone_record["group"] = Intake.table_name
        if clone_record["end"].nil?
          significant_duration = record["completed_at"] - record["started_at"] > 360 if record["completed_at"]
          clone_record["type"] = significant_duration ? "range" : nil
          clone_record["end"] = significant_duration ? record["completed_at"] : nil
        end

        # for visualization
        clone_record["title"] = "<pre><code style='font-size:0.7em'>#{JSON.pretty_generate(clone_record)}</code></pre>"
        clone_record["className"] = record["type"]
      end
    end
  end

  # :reek:FeatureEnvy
  def hearings_timeline_data
    exported_records(Intake).map do |record|
      record.clone.tap do |clone_record|
        clone_record["id"] = "HEARING#{record['type']}#{record['id']}"
        clone_record["record_id"] = record["id"]
        clone_record["tableName"] = Intake.table_name
        clone_record["content"] = "#{record['type']}_#{record['id']}"
        clone_record["intakeType"] = record["type"]
        clone_record["start"] = record["started_at"]
        clone_record["end"] = Time.zone.now if record["completed_at"].nil?
        clone_record["type"] = "range" 

        clone_record["group"] = Intake.table_name
        if clone_record["end"].nil?
          significant_duration = record["completed_at"] - record["started_at"] > 360 if record["completed_at"]
          clone_record["type"] = significant_duration ? "range" : nil
          clone_record["end"] = significant_duration ? record["completed_at"] : nil
        end

        # for visualization
        clone_record["title"] = "<pre><code style='font-size:0.7em'>#{JSON.pretty_generate(clone_record)}</code></pre>"
        clone_record["className"] = record["type"]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
