# frozen_string_literal: true

##
# Maps Intake records (exported by SanitizedJsonExporter) to AppealEventData objects for use by ExplainController.

class Explain::IntakeRecordToEventMapper < Explain::RecordToEventMapper
  def initialize(record, object_id_cache)
    super("intake", record,
          object_id_cache: object_id_cache,
          default_context_id: "#{record['detail_type']}_#{record['detail_id']}")
  end

  def events
    [
      intake_started_event,
      (intake_completed_event if record["completed_at"])
    ].compact
  end

  private

  def intake_started_event
    relevant_data_keys = %w[completion_status error_code cancel_reason cancel_other].freeze
    new_event(record["started_at"], "started",
              comment: "#{user(record['user_id'])} started intake",
              relevant_data_keys: relevant_data_keys)
  end

  def intake_completed_event
    new_event(record["completed_at"], "intake_completed", object_type: "milestone")
  end
end
