# frozen_string_literal: true

require "action_view"

# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  def milestones_as_event_data(last_timestamp)
    all_events = sje.records_hash[Appeal.table_name].map do |appeal|
      mapper = RecordToMilestoneEventMapper.new("milestone", appeal, object_id_cache)
      [
        mapper.receipt_date_event,
        mapper.appeal_creation_event
      ] + mapper.time_period_events(last_timestamp)
    end
    # binding.pry
    all_events.flatten.compact.sort_by(&:timestamp)
  end

  # :reek:FeatureEnvy
  def tasks_as_event_data
    # binding.pry
    sje.records_hash[Task.table_name].map do |task|
      mapper = RecordToTaskEventMapper.new(Task.name.downcase, task, object_id_cache)
      [
        mapper.task_created_or_assigned_event,
        mapper.task_started_event,
        mapper.task_closed_event,
        (mapper.milestone_event if task["status"] == "completed")
      ]
    end.flatten.compact.sort_by { |event| [event.timestamp, event.object_id] }
  end

  private

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

    def initialize(object_type, record, object_id_cache)
      @record = record
      @object_type = object_type
      @object_id_cache = object_id_cache
    end

    def duration_in_words(from_time, to_time, options = {})
      time_delta = to_time.to_date - from_time.to_date
      return distance_of_time_in_words(from_time, to_time, options) if time_delta < 1.year

      "#{(time_delta / 1.month).round} months"
    rescue StandardError
      "from #{from_time} (#{from_time.class}) to #{to_time} (#{to_time.class})"
    end

    def task_object_id
      @object_id_cache[:tasks][record["id"]]
    end

    def new_event(timestamp, context_id, object_id, event_type, object_type: @object_type)
      ExplainController::AppealEventData.new(
        timestamp, context_id, object_type, object_id, event_type
      ).tap do |event|
        event.details = record
        event.relevant_data = {}
        yield event if block_given?
      end
    end
  end

  class RecordToMilestoneEventMapper < RecordToEventMapper
    def initialize(object_type, record, object_id_cache)
      super
    end

    def new_milestone_event(timestamp, event_type, &block)
      new_event(timestamp, appeal_object_id, appeal_object_id, event_type, &block)
    end

    def appeal_object_id
      "#{Appeal.name}_#{record['id']}"
    end

    def receipt_date
      record["receipt_date"]
    end

    def receipt_date_event
      new_milestone_event(receipt_date, "receipt_date")
    end

    def appeal_creation_event
      duration_in_words = duration_in_words(receipt_date, record["created_at"])
      new_milestone_event(record["created_at"], "appeal_created") do |event|
        event.relevant_data = { stream_type: record["stream_type"],
                                docket_type: record["docket_type"],
                                closest_regional_office: record["closest_regional_office"] }
        event.comment = "#{duration_in_words} from receipt date"
      end
    end

    def time_period_events(last_timestamp)
      current_time = receipt_date
      month_count = 0
      events = []
      while current_time < last_timestamp
        month_count += 1
        current_time += 1.month
        events << ExplainController::AppealEventData.new(
          current_time, appeal_object_id, "month", "month_#{month_count}", "month"
        )
      end
      events
    end
  end

  class RecordToTaskEventMapper < RecordToEventMapper
    def initialize(object_type, record, object_id_cache)
      super
    end

    def new_task_event(timestamp, event_type, &block)
      new_event(timestamp, appeal_object_id, task_object_id, event_type, &block)
    end

    def appeal_object_id
      "#{record['appeal_type']}_#{record['appeal_id']}"
    end

    def task_label
      record["type"].constantize.label
    end

    def timeline_title
      # To-do: eager load slow queries or use alternative indicator
      Task.find(record["id"]).timeline_title
    end

    def task_assigned_by
      @object_id_cache[:users][record["assigned_by_id"]]
    end

    def task_assigned_to
      obj_type = (record["assigned_to_type"] == "Organization") ? :orgs : :users
      @object_id_cache[obj_type][record["assigned_to_id"]]
    end

    def task_cancelled_by
      @object_id_cache[:users][record["cancelled_by_id"]]
    end

    def task_parent_id
      @object_id_cache[:tasks][record["parent_id"]]
    end

    TASK_TYPES_TO_SKIP_CREATION_EVENTS = %w[RootTask DistributionTask HearingTask AssignHearingDispositionTask].freeze

    def task_created_or_assigned_event
      return if TASK_TYPES_TO_SKIP_CREATION_EVENTS.include?(record["type"])

      record["assigned_at"] ? task_assigned_event : task_created_event
    end

    def task_created_and_or_assigned_event
      return if TASK_TYPES_TO_SKIP_CREATION_EVENTS.include?(record["type"])

      return task_assigned_event if record["assigned_at"] == record["created_at"]

      [task_created_event, task_assigned_event]
    end

    def blocked_task_id
      task_parent_id unless task_parent_id&.start_with?("RootTask_")
    end

    def task_created_event
      new_task_event(record["created_at"], "opened") do |event|
        event.comment = "#{task_assigned_by} created task '#{task_label}'"
        event.relevant_data[:blocks] = blocked_task_id if blocked_task_id
      end
    end

    def task_assigned_event
      new_task_event(record["assigned_at"], "opened") do |event|
        event.comment = "#{task_assigned_by} assigned '#{task_label}' to #{task_assigned_to}"
        event.relevant_data[:blocks] = blocked_task_id if blocked_task_id
        event.details.merge!(assigned_by: task_assigned_by,
                             assigned_to: task_assigned_to)
      end
    end

    def task_started_event
      return nil unless record["started_at"]

      wait_time = duration_in_words(record["assigned_at"], record["started_at"]) if record["assigned_at"]
      new_task_event(record["started_at"], "started") do |event|
        event.comment = "#{task_assigned_to} started task #{wait_time} after assignment"
      end
    end

    def task_closed_event
      return nil unless record["closed_at"]

      new_task_event(record["closed_at"], "closed") do |event|
        start_time = record["started_at"] || record["assigned_at"] || record["created_at"]
        duration_in_words = duration_in_words(start_time, record["closed_at"])
        user = (record["status"] == "cancelled") ? task_cancelled_by : task_assigned_to
        event.comment = "#{user} #{record['status']} '#{task_label}' in #{duration_in_words}"

        event.relevant_data[:timeline_title] = timeline_title
        event.relevant_data[:unblocks] = blocked_task_id if blocked_task_id
        event.details[:duration] = record["closed_at"] - start_time
      end
    end

    TASK_TYPES_FOR_MILESTONE_EVENTS = %w[HearingTask DistributionTask
                                         JudgeDecisionReviewTask QualityReviewTask BvaDispatchTask
                                         RootTask].freeze

    def milestone_event
      return nil unless record["status"] == "completed" && TASK_TYPES_FOR_MILESTONE_EVENTS.include?(record["type"])

      return nil if record["type"] == "BvaDispatchTask" && record["assigned_to_id"] != BvaDispatch.singleton.id

      new_event(record["closed_at"] + 1, appeal_object_id, task_object_id,
                "milestone", object_type: "milestone") do |event|
        duration_in_words = duration_in_words(record["created_at"], record["closed_at"])
        event.comment = "'#{task_label}' completed in #{duration_in_words}"
        event.relevant_data[:timeline_title] = timeline_title
        event.relevant_data[:unblocks] = blocked_task_id if blocked_task_id
        event.details[:duration] = record["closed_at"] - record["created_at"]
      end
    end
  end
end
