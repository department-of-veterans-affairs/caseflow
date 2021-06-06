# frozen_string_literal: true

require "action_view"

# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  # :reek:TooManyInstanceVariables
  class AppealEventData
    attr_reader :timestamp, :context_id, :object_type, :object_id, :event_type
    attr_accessor :comment, :relevant_data, :details, :row_order

    # Maps event_type to row_order, which is used for sorting for events with the same timestamp
    # Handles the scenario where task is reassigned
    # Assumes that event_types are for different object_ids
    ROW_ORDERING = {
      "cancelled" => -2,
      "completed" => -1,
      "milestone" => 0,
      "created" => 2,
      "assigned" => 3,
      "on_hold" => 5,
      "started" => 6,
      "in_progress" => 7
    }.freeze

    def initialize(timestamp, context_id, object_type, object_id, event_type)
      @timestamp = timestamp
      @context_id = context_id
      @object_type = object_type
      @object_id = object_id
      @event_type = event_type
      @row_order = ROW_ORDERING[event_type] || 0
    end

    CLOSED_STATUSES = %w[completed cancelled milestone].freeze

    def <=>(other)
      return timestamp <=> other.timestamp unless timestamp == other.timestamp

      return row_order <=> other.row_order unless row_order == other.row_order

      if CLOSED_STATUSES.include?(event_type)
        # sort by id in reverse ordering to close child tasks first
        other.details["id"] <=> details["id"]
      else
        details["id"] <=> other.details["id"]
      end
    rescue StandardError
      raise "#{self} <=> #{other}"
    end
  end

  def appeal_as_event_data(last_timestamp)
    all_events = sje.records_hash[Appeal.table_name].map do |appeal|
      mapper = AppealRecordToEventMapper.new(appeal)
      mapper.events + mapper.timing_events(last_timestamp)
    end
    all_events += sje.records_hash[Intake.table_name].map do |intake|
      IntakeRecordToEventMapper.new(intake, object_id_cache).events
    end
    all_events.flatten.compact.sort
  end

  # :reek:FeatureEnvy
  def tasks_as_event_data
    sje.records_hash[Task.table_name].map do |task|
      TaskRecordToEventMapper.new(task, object_id_cache).events
    end.flatten.compact.sort
  end

  private

  def records_hash_for(appeal)
    sje.records_hash.map do |table_name, records|
      next unless records.is_a?(Array)

      filtered_records = records.select do |record|
        record.find do |attrib_name, value|
          value == appeal["id"] && attrib_name.end_with?("id")
        end
      end
      [table_name, filtered_records]
    end.compact.to_h
  end

  def object_id_cache
    @object_id_cache ||= {
      # appeals: sje.records_hash[Appeal.table_name].map { |appeal| [appeal["id"], appeal["name"]] }.to_h,
      orgs: sje.records_hash[Organization.table_name].map { |org| [org["id"], org["name"]] }.to_h,
      users: sje.records_hash[User.table_name].map { |user| [user["id"], user["css_id"]] }.to_h,
      tasks: sje.records_hash[Task.table_name].map { |task| [task["id"], "#{task['type']}_#{task['id']}"] }.to_h
    }
  end

  class RecordToEventMapper
    include ActionView::Helpers::DateHelper # defines distance_of_time_in_words

    attr_reader :record

    def initialize(object_type, record,
                   object_id_cache: {},
                   default_context_id: "#{record['type']}_#{record['id']}",
                   default_object_id: "#{record['type']}_#{record['id']}")
      @record = record
      @object_type = object_type
      @object_id_cache = object_id_cache
      @default_context_id = default_context_id
      @default_object_id = default_object_id
    end

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
    def new_event(timestamp, event_type,
                  context_id: @default_context_id,
                  object_id: @default_object_id,
                  object_type: @object_type,
                  comment: nil,
                  relevant_data_keys: [])
      AppealEventData.new(
        timestamp, context_id, object_type, object_id, event_type
      ).tap do |event|
        event.details = record
        event.comment = comment if comment
        event.relevant_data = relevant_data_keys.map do |attribute|
          [attribute, record[attribute]] if record[attribute]
        end.compact.to_h
        yield event if block_given?
      end
    end
    # rubocop:enable Metrics/ParameterLists
  end

  class AppealRecordToEventMapper < RecordToEventMapper
    def initialize(record)
      super("appeal", record,
            default_context_id: "#{Appeal.name}_#{record['id']}",
            default_object_id: "#{Appeal.name}_#{record['id']}")
    end

    def events
      [
        receipt_date_event,
        appeal_creation_event
      ]
    end

    def timing_events(last_timestamp)
      current_time = receipt_date
      month_count = 0
      events = []
      while current_time < last_timestamp
        month_count += 1
        current_time += 1.month
        events << AppealEventData.new(current_time, @default_object_id, "clock", "month_#{month_count}", "month")
      end
      events
    end

    private

    def receipt_date
      record["receipt_date"]
    end

    def receipt_date_event
      new_event(receipt_date, "receipt_date", object_type: "milestone")
    end

    def appeal_creation_event
      duration_in_words = duration_in_words(receipt_date, record["created_at"])
      relevant_data_keys = %w[stream_type docket_type closest_regional_office].freeze
      new_event(record["created_at"], "appeal_created",
                comment: "#{duration_in_words} from receipt date",
                relevant_data_keys: relevant_data_keys)
    end
  end

  class IntakeRecordToEventMapper < RecordToEventMapper
    def initialize(record, object_id_cache)
      super("intake", record,
            object_id_cache: object_id_cache,
            default_context_id: "#{record['detail_type']}_#{record['detail_id']}")
    end

    def events
      [
        intake_started_event,
        intake_completed_event
      ]
    end

    private

    def intake_started_event
      relevant_data_keys = %w[completion_status error_code cancel_reason cancel_other].freeze
      new_event(record["started_at"], "started",
                comment: "#{user(record['user_id'])} started intake",
                relevant_data_keys: relevant_data_keys)
    end

    def intake_completed_event
      return unless record["completed_at"]

      new_event(record["completed_at"], "intake_completed", object_type: "milestone")
    end
  end

  class TaskRecordToEventMapper < RecordToEventMapper
    def initialize(record, object_id_cache)
      super("task", record,
        object_id_cache: object_id_cache,
        default_context_id: "#{record['appeal_type']}_#{record['appeal_id']}")
    end

    def events
      [
        task_created_or_assigned_event,
        task_started_event,
        task_closed_event,
        (milestone_event if record["status"] == "completed")
      ]
    end

    private

    def task_label
      record["type"].constantize.label
    end

    def timeline_title
      # To-do: eager load slow queries or use alternative indicator
      Task.find(record["id"]).timeline_title
    end

    def task_assigned_by
      user(record["assigned_by_id"])
    end

    def task_assigned_to
      obj_type = (record["assigned_to_type"] == "Organization") ? :orgs : :users
      @object_id_cache[obj_type][record["assigned_to_id"]]
    end

    TASK_TYPES_THAT_SKIP_CREATION_EVENTS = %w[RootTask DistributionTask HearingTask].freeze

    def task_created_or_assigned_event
      return if TASK_TYPES_THAT_SKIP_CREATION_EVENTS.include?(record["type"])

      record["assigned_at"] ? task_assigned_event : task_created_event
    end

    def task_created_and_or_assigned_event
      return if TASK_TYPES_THAT_SKIP_CREATION_EVENTS.include?(record["type"])

      return task_assigned_event if record["assigned_at"] == record["created_at"]

      [task_created_event, task_assigned_event]
    end

    def blocked_task_id
      task_parent_id = task(record["parent_id"])
      task_parent_id unless task_parent_id&.start_with?("RootTask_")
    end

    def task_created_event
      new_event(record["created_at"], "created") do |event|
        event.comment = "#{task_assigned_by} created task '#{task_label}'"
        event.relevant_data[:blocks] = blocked_task_id if blocked_task_id
      end
    end

    def task_assigned_event
      new_event(record["assigned_at"], "assigned") do |event|
        event.comment = "#{task_assigned_by} assigned '#{task_label}' to #{task_assigned_to}"
        event.relevant_data[:blocks] = blocked_task_id if blocked_task_id
        event.details.merge!(assigned_by: task_assigned_by,
                             assigned_to: task_assigned_to)
      end
    end

    def task_started_event
      return nil unless record["started_at"]

      ending_phrase = if record["assigned_at"]
                        wait_time = duration_in_words(record["assigned_at"], record["started_at"])
                        "#{wait_time} after assignment"
                      end
      new_event(record["started_at"], "started",
                comment: "#{task_assigned_to} started task #{ending_phrase}")
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def task_closed_event
      return nil unless record["closed_at"]

      new_event(record["closed_at"], record["status"]) do |event|
        start_time = record["started_at"] || record["assigned_at"] || record["created_at"]
        duration_in_words = duration_in_words(start_time, record["closed_at"])
        user = (record["status"] == "cancelled") ? user(record["cancelled_by_id"]) : task_assigned_to
        event.comment = "#{user} #{record['status']} '#{task_label}' in #{duration_in_words}"

        # To-do: only show timeline_title if task is shown in timeline
        event.relevant_data[:timeline_title] = timeline_title if record["status"] == "completed"
        event.relevant_data[:unblocks] = blocked_task_id if blocked_task_id
        event.details[:duration] = record["closed_at"] - start_time
      end
    end

    TASK_TYPES_FOR_MILESTONE_EVENTS = %w[HearingTask DistributionTask
                                         JudgeDecisionReviewTask QualityReviewTask BvaDispatchTask
                                         RootTask].freeze

    def milestone_event
      # ignore BvaDispatchTask that are assigned to users; use the BvaDispatchTask assigned to org instead
      return nil if record["type"] == "BvaDispatchTask" && record["assigned_to_type"] == "User"

      return nil unless record["status"] == "completed" && TASK_TYPES_FOR_MILESTONE_EVENTS.include?(record["type"])

      new_event(record["closed_at"], "milestone", object_type: "milestone") do |event|
        duration_in_words = duration_in_words(record["created_at"], record["closed_at"])
        event.comment = "'#{task_label}' completed in #{duration_in_words}"
        event.details[:duration] = record["closed_at"] - record["created_at"]
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  end
end
