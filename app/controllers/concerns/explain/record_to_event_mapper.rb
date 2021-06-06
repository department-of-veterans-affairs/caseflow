# frozen_string_literal: true

##
# Base class that maps records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::RecordToEventMapper
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

    # Maps event_type to row_order, which is used for sorting for events with the same timestamp
    # Handles the scenario where task is reassigned
    # Assumes that event_types are for different object_ids
    ROW_ORDERING = {
      "month" => -10,
      "cancelled" => -2,
      "completed" => -1,
      "milestone" => 0,
      "created" => 2,
      "assigned" => 3,
      "on_hold" => 5,
      "started" => 6,
      "in_progress" => 7
    }.freeze

    def initialize(timestamp, context_id, category, object_id, event_type)
      @timestamp = timestamp || Time.now.utc.end_of_year
      @context_id = context_id
      @category = category
      @object_id = object_id
      @event_type = event_type
      @row_order = ROW_ORDERING[event_type] || 0
    end

    CLOSED_STATUSES = %w[completed cancelled milestone].freeze

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    def <=>(other)
      return timestamp <=> other.timestamp unless timestamp == other.timestamp

      # row_order is an ordering based on event_type
      return row_order <=> other.row_order unless row_order == other.row_order

      if details.key?("id") && other.details.key?("id")
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
