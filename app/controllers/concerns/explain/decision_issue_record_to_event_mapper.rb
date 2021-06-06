# frozen_string_literal: true

##
# Maps DecisionIssue records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::DecisionIssueRecordToEventMapper < Explain::RecordToEventMapper
  # :reek:FeatureEnvy
  def initialize(record, req_issue_record)
    @req_issue_record = req_issue_record
    super("issue", record,
          default_context_id: "#{record['decision_review_type']}_#{record['decision_review_id']}",
          default_object_id: "DecisionIssue_#{record['id']}")
  end

  def events
    [
      decision_event,
      (decision_deleted_event if record["deleted_at"])
    ].compact
  end

  private

  def request_issue
    "RequestIssue_#{@req_issue_record['id']}"
  end

  RELEVANT_DATA_KEYS = %w[description decision_text diagnostic_code
                          caseflow_decision_date
                          subject_text percent_number].freeze

  def decision_event
    new_event(record["created_at"], "decision",
              comment: "#{record['disposition']} #{record['benefit_type']} for #{request_issue}",
              relevant_data_keys: RELEVANT_DATA_KEYS)
  end

  def decision_deleted_event
    new_event(record["deleted_at"], "deleted",
              comment: "decision #{record['disposition']}")
  end
end
