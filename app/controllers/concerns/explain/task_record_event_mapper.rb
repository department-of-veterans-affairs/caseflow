# frozen_string_literal: true

##
# Maps Task records (exported by SanitizedJsonExporter) to AppealEventData objects for use by ExplainController.

class Explain::TaskRecordEventMapper < Explain::RecordEventMapper
  # :reek:FeatureEnvy
  def initialize(record, object_id_cache)
    super("task", record,
      object_id_cache: object_id_cache,
      default_context_id: "#{record['appeal_type']}_#{record['appeal_id']}")
  end

  def events
    [
      task_created_or_assigned_event,
      (task_started_event if record["started_at"]),
      (task_closed_event if record["closed_at"]),
      (milestone_event if record["status"] == "completed")
    ].compact
  end

  private

  def task_label
    record["type"].constantize.label
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
    ending_phrase = if record["assigned_at"]
                      wait_time = duration_in_words(record["assigned_at"], record["started_at"])
                      "#{wait_time} after assignment"
                    end
    new_event(record["started_at"], "started",
              comment: "#{task_assigned_to} started task #{ending_phrase}")
  end

  # rubocop:disable Metrics/AbcSize
  def task_closed_event
    new_event(record["closed_at"], record["status"]) do |event|
      start_time = record["started_at"] || record["assigned_at"] || record["created_at"]
      duration_in_words = duration_in_words(start_time, record["closed_at"])
      user = (record["status"] == "cancelled") ? user(record["cancelled_by_id"]) : task_assigned_to
      event.comment = "#{user} #{record['status']} '#{task_label}' in #{duration_in_words}"

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

    new_event(record["closed_at"], "milestone", category: "milestone") do |event|
      duration_in_words = duration_in_words(record["created_at"], record["closed_at"])
      event.comment = "'#{task_label}' completed in #{duration_in_words}"
      event.details[:duration] = record["closed_at"] - record["created_at"]
    end
  end
  # rubocop:enable Metrics/AbcSize
end
