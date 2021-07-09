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

  private

  PHASES_TASK_TYPES = %w[DistributionTask JudgeDecisionReviewTask BvaDispatchTask].freeze

  # :reek:FeatureEnvy
  def tasks_timeline_data
    phases_tasks + nonphases_tasks
  end

  # :reek:FeatureEnvy
  def intake_timeline_data
    exported_records(Intake).map do |record|
      TimelineSpanData.new(Intake, record,
                           start_time: record["started_at"],
                           end_time: record["completed_at"],
                           short_duration_threshold: 360,
                           short_duration_display_type: nil,
                           group: "others")
    end
  end

  # :reek:FeatureEnvy
  def hearings_timeline_data
    hearing_days = exported_records(HearingDay).index_by { |rec| rec["id"] }
    # virtual_hearings = exported_records(VirtualHearing).index_by { |rec| rec["hearing_id"] }
    exported_records(Hearing).map do |record|
      hearing_day = hearing_days[record["hearing_day_id"]]
      # virtual_hearing = virtual_hearings[hearing["id"]]
      # slot_time = record["scheduled_time"]&.strftime("%H:%M")
      TimelineSpanData.new(Hearing, record,
                           status: record["disposition"],
                           start_time: hearing_day["scheduled_for"],
                           end_time: hearing_day["scheduled_for"],
                           short_duration_threshold: 1,
                           short_duration_display_type: nil,
                           group: "others")
    end
  end

  def phases_tasks
    exported_records(Task)
      .select { |record| PHASES_TASK_TYPES.include?(record["type"]) }
      .map do |record|
      [TimelineSpanData.new(Task, record, group: "phase"),
       create_background_task(record)]
    end.flatten
  end

  def nonphases_tasks
    exported_records(Task)
      .reject { |record| PHASES_TASK_TYPES.include?(record["type"]) }
      .map { |record| create_nonphase_task_data(record) }
  end

  def create_nonphase_task_data(record)
    group = (record["status"] == "cancelled") ? "cancelled_tasks" : "tasks"
    TimelineSpanData.new(Task, record, group: group, short_duration_threshold: 60).tap do |event|
    end
  end

  def create_background_task(record)
    TimelineSpanData.new(Task, record,
                         id: "#{record['type']}#{record['id']}_bkgd",
                         type: "background",
                         group: nil, # show across all groups
                         # a corresponding labeled task lines up with this background, so use empty label
                         label: "")
  end

  # To-do: consider moving visualization code to explain-appeal.js
  # :reek:TooManyInstanceVariables
  class TimelineSpanData
    attr_reader :id, :record_id
    attr_accessor :start, :end, :group, :type, :styling_classes

    TOOLTIP_STYLE = "font-size:0.7em; white-space: pre-line; width: 100px;"

    # rubocop:disable Metrics/ParameterLists
    # :reek:LongParameterList
    def initialize(klass, record,
                   record_type = record["type"] || klass.table_name.singularize,
                   id: "#{record_type}#{record['id']}",
                   start_time: record["created_at"],
                   end_time: record["closed_at"],
                   type: "range",
                   short_duration_threshold: 0, # in seconds
                   short_duration_display_type: "point",
                   status: record["status"],
                   group: "others",
                   label: "#{record_type}_#{record['id']}",
                   tooltip: "<pre><code style=#{TOOLTIP_STYLE}>#{JSON.pretty_generate(record)}</code></pre>")
      @record_type = record_type
      @id = id
      @record_id = record["id"]
      @table_name = klass.table_name
      @status = status
      @content = label
      @start = start_time

      # `title` is displayed as the tooltip
      @title = tooltip
      # `type` is one of the vis-timeline item types: range, box, point, background
      # See https://visjs.github.io/vis-timeline/docs/timeline/#items
      if short_duration?(end_time, short_duration_threshold)
        @end = nil
        @type = short_duration_display_type
      else
        @end = end_time || Time.zone.now
        @type = type
      end

      # `group` corresponds with a group defined in function `groupEventItems` of explain-appeal.js
      # See https://visjs.github.io/vis-timeline/docs/timeline/#groups
      @group = group
    end
    # rubocop:enable Metrics/ParameterLists

    def short_duration?(end_time, short_duration_threshold)
      end_time && (end_time - @start < short_duration_threshold)
    end
  end
end
