# frozen_string_literal: true

# Used by ExplainController to build the data for visualizing a timeline based on
# exported data from SanitizedJsonExporter.

module ExplainTimelineConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def timeline_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    (tasks_timeline_data + intake_timeline_data + hearings_timeline_data).map(&:as_json)
  end

  BACKGROUND_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask BvaDispatchTask].freeze

  # clone_record["type"] is one of the vis-timeline item types: range, box, point, background
  # clone_record["title"] is displayed as the tooltip
  # See https://visjs.github.io/vis-timeline/docs/timeline/#items

  # clone_record["group"] corresponds with a group defined in function `groupEventItems` of explain-appeal.js
  # See https://visjs.github.io/vis-timeline/docs/timeline/#groups

  # rubocop:disable Metrics/MethodLength
  # :reek:FeatureEnvy
  def tasks_timeline_data
    exported_records(Task)
      .select { |record| BACKGROUND_TASK_TYPES.include?(record["type"]) }
      .map do |record|
        TimelineSpanData.new(Task, record,
                             id: "#{record['type']}#{record['id']}_bkgd",
                             type: "background",
                             group: nil,
                             label: "").tap do |event|
          # for visualization
          event.styling_classes += " task_#{record['status']}" # TODO: check this
        end
      end.compact +
      exported_records(Task).map do |record|
        TimelineSpanData.new(Task, record).tap do |event|
          if BACKGROUND_TASK_TYPES.include?(record["type"])
            event.group = "phase"
          elsif record["status"] == "cancelled"
            event.group = "cancelled_tasks"
          end

          if record["closed_at"]
            significant_duration = record["closed_at"] - record["created_at"] > 60
            if !significant_duration
              event.type = "point"
              event.end = nil
            end
          end

          # for visualization
          event.styling_classes += " task_#{record['status']}" # TODO: check this
        end
      end
  end

  # :reek:TooManyInstanceVariables
  class TimelineSpanData
    attr_reader :id, :record_id
    attr_accessor :start, :end, :group, :type, :styling_classes

    TOOLTIP_STYLE = "font-size:0.7em; white-space: pre-line; width: 100px;"
    # rubocop:disable Metrics/ParameterLists
    def initialize(klass, record,
                   record_type: record["type"],
                   id: "#{record['type']}#{record['id']}",
                   start_time: record["created_at"],
                   end_time: record["closed_at"],
                   type: "range",
                   group: klass.table_name,
                   label: "#{record['type']}_#{record['id']}",
                   tooltip: "<pre><code style=#{TOOLTIP_STYLE}>#{JSON.pretty_generate(record)}</code></pre>")
      @record_type = record_type
      @id = id
      @record_id = record["id"]
      @table_name = klass.table_name
      @content = label
      @start = start_time
      @end = end_time || Time.zone.now
      @type = type

      # for visualization
      @title = tooltip
      @group = group
      @styling_classes = record["type"]
    end
    # rubocop:enable Metrics/ParameterLists
  end

  # :reek:FeatureEnvy
  def intake_timeline_data
    exported_records(Intake).map do |record|
      TimelineSpanData.new(Intake, record,
                           start_time: record["started_at"],
                           end_time: record["completed_at"],
                           group: "others").tap do |event|
        if record["completed_at"]
          significant_duration = record["completed_at"] - record["started_at"] > 360
          if !significant_duration
            event.type = nil
            event.end = nil
          end
        end
      end
    end
  end

  # :reek:FeatureEnvy
  def hearings_timeline_data
    exported_records(Hearing).map do |record|
      TimelineSpanData.new(Hearing, record, end_time: record["updated_at"]).tap do |_event|
        # slot_time = record["scheduled_time"]&.strftime("%H:%M")

        # significant_duration = record["completed_at"] - record["started_at"] > 60 if record["completed_at"]
        # if !significant_duration
        #   event.type = nil
        #   event.end = nil
        # end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
