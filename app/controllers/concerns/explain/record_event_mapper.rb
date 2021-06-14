# frozen_string_literal: true

##
# Base class that maps records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::RecordEventMapper
  include ActionView::Helpers::DateHelper # defines distance_of_time_in_words

  attr_reader :record

  # :reek:FeatureEnvy
  def initialize(category, record,
                 object_id_cache: {},
                 default_context_id: "#{record['type']}_#{record['id']}",
                 default_object_id: "#{record['type']}_#{record['id']}")
    @category = category
    @record = record
    @object_id_cache = object_id_cache
    @default_context_id = default_context_id
    @default_object_id = default_object_id
  end

  # :reek:FeatureEnvy
  def duration_in_words(from_time, to_time, options = {})
    delta_days = (to_time.to_date - from_time.to_date).round
    return distance_of_time_in_words(from_time, to_time, options) if delta_days < 365

    "#{(delta_days / 30).round} months"
  rescue StandardError
    "from #{from_time} (#{from_time.class}) to #{to_time} (#{to_time.class})"
  end

  def user(id)
    @object_id_cache[:users][id]
  end

  def task(id)
    @object_id_cache[:tasks][id]
  end

  # rubocop:disable Metrics/ParameterLists
  # :reek:LongParameterList
  def new_event(timestamp, event_type,
                context_id: @default_context_id,
                object_id: @default_object_id,
                category: @category,
                comment: nil,
                relevant_data_keys: [])
    AppealEventData.new(
      timestamp, context_id, category, object_id, event_type
    ).tap do |event|
      event.details = record
      event.comment = comment if comment
      event.relevant_data = relevant_data_keys.map do |attribute|
        [attribute, record[attribute]] if record[attribute]
      end.compact.to_h
      yield event if block_given?

      event.relevant_data = nil if event.relevant_data.empty?
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # :reek:TooManyInstanceVariables
  class AppealEventData
    attr_reader :timestamp, :context_id, :category, :object_id, :event_type
    attr_accessor :comment, :relevant_data, :details, :row_order

    # For events with the same timestamp, this hash maps "#{category} #{event_type}", "#{event_type}", or
    # "#{category}" to row_order, which is used for sorting.
    ROW_ORDERING = {
      "clock" => -20,

      # order before "milestone"
      "appeal created" => -8,
      "issue created" => -7,
      "issue decision" => -6, # before JudgeDecisionReviewTask "task completed"

      # order before "task completed" and "milestone"
      "issue closed" => -3,
      "document processed" => -2, # for DecisionDocuments

      # handle scenario where task is reassigned.
      "task cancelled" => 7,
      "task completed" => 8,
      "milestone" => 10,
      "task created" => 13,
      "task assigned" => 14,
      "task on_hold" => 15,
      "task started" => 16,
      "task in_progress" => 17
    }.freeze

    def initialize(timestamp, context_id, category, object_id, event_type)
      @timestamp = timestamp || Time.now.utc.end_of_year
      @context_id = context_id
      @category = category
      @object_id = object_id
      @event_type = event_type
      @row_order = ROW_ORDERING["#{category} #{event_type}"] || ROW_ORDERING[event_type] || ROW_ORDERING[category] || 0
    end

    CLOSED_STATUSES = %w[completed cancelled milestone].freeze

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    def <=>(other)
      return timestamp <=> other.timestamp unless timestamp == other.timestamp

      # row_order is an ordering based on event_type
      return row_order <=> other.row_order unless row_order == other.row_order

      if details&.key?("id") && other.details&.key?("id")
        # sort by id in reverse ordering to close child tasks first
        return other.details["id"] <=> details["id"] if CLOSED_STATUSES.include?(event_type)

        return details["id"] <=> other.details["id"]
      end

      0
    rescue StandardError => error
      # binding.pry
      raise "#{error}:\n #{inspect}\n #{other.inspect}"
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize
  end
end
