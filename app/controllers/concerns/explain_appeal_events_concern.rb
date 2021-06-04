# frozen_string_literal: true

require "action_view"

# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  TASK_TYPES_TO_SKIP_CREATION_EVENTS = %w[RootTask DistributionTask HearingTask AssignHearingDispositionTask].freeze

  # :reek:FeatureEnvy
  def tasks_as_event_data
    # binding.pry
    sje.records_hash[Task.table_name].map do |record|
      mapper = RecordToEventMapper.new(Task.name.downcase, record, object_id_cache)
      [
        (mapper.task_created_or_assigned_event unless TASK_TYPES_TO_SKIP_CREATION_EVENTS.include?(record["type"])),
        mapper.task_started_event,
        mapper.task_closed_event
      ]
    end.flatten.compact.sort_by(&:timestamp)
  end

  private

  def object_id_cache
    @object_id_cache ||= {
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

    def appeal_object_id
      "#{record['appeal_type']}_#{record['appeal_id']}"
    end

    def task_object_id
      @object_id_cache[:tasks][record["id"]]
    end

    def task_label
      record['type'].constantize.label
    end

    def task_assigned_by
      @object_id_cache[:users][record["assigned_by_id"]]
    end

    def task_assigned_to
      obj_type = (record["assigned_to_type"] == "Organization") ? :orgs : :users
      @object_id_cache[obj_type][record["assigned_to_id"]]
    end

    def task_parent_id
      @object_id_cache[:tasks][record["parent_id"]]
    end

    def task_created_or_assigned_event
      record["assigned_at"] ? task_assigned_event : task_created_event
    end

    def new_appeal_event(timestamp, event_type)
      ExplainController::AppealEventData.new(
        timestamp, appeal_object_id, @object_type, task_object_id, event_type
      ).tap do |event|
        event.details = record
        yield event if block_given?
      end
    end

    def task_created_event
      new_appeal_event(record["created_at"], "opened") do |event|
        event.comment = "created task"
        event.relevant_data = { blocks_task: task_parent_id }
      end
    end

    def task_assigned_event
      new_appeal_event(record["assigned_at"], "opened") do |event|
        event.comment = "#{task_assigned_by} assigned '#{task_label}' to #{task_assigned_to}"
        event.relevant_data = { blocks_task: task_parent_id }
        event.details.merge!(assigned_by: task_assigned_by,
                             assigned_to: task_assigned_to)
      end
    end

    def task_started_event
      return nil unless record["started_at"]

      wait_time = distance_of_time_in_words(record["assigned_at"], record["started_at"]) if record["assigned_at"]
      new_appeal_event(record["started_at"], "started") do |event|
        event.comment = "#{task_assigned_to} started task #{wait_time} after assignment"
        event.relevant_data = {}
      end
    end

    def task_closed_event
      return nil unless record["closed_at"]

      new_appeal_event(record["closed_at"], "closed") do |event|
        duration_in_words = distance_of_time_in_words(record["created_at"], record["closed_at"])
        event.comment = "#{task_assigned_to} #{record['status']} '#{task_label}' in #{duration_in_words}"
        event.relevant_data = { unblocks_task: task_parent_id }
        event.details.merge[:duration] = record["closed_at"] - record["created_at"]
      end
    end
  end
end
