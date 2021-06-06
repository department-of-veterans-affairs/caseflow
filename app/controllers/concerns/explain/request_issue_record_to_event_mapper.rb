# frozen_string_literal: true

##
# Maps RequestIssue records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::RequestIssueRecordToEventMapper < Explain::RecordToEventMapper
  # :reek:FeatureEnvy
  def initialize(record)
    super("issue", record,
          default_context_id: "#{record['decision_review_type']}_#{record['decision_review_id']}",
          default_object_id: "#{record['type']}_#{record['id']}")
  end

  def events
    [
      request_issue_created_event,
      (request_issue_closed_event if record["closed_at"])
    ].compact
  end

  private

  RELEVANT_DATA_KEYS = %w[ineligible_reason notes
                          untimely_exemption untimely_exemption_notes
                          edited_description
                          covid_timeliness_exempt
                          decision_sync_processed_at decision_sync_error
                          contention_removed_at
                          contested_rating_issue_diagnostic_code
                          contested_issue_description
                          nonrating_issue_description nonrating_issue_category
                          is_unidentified unidentified_issue_text
                          decision_date decision_sync_error].freeze

  def request_issue_created_event
    new_event(record["created_at"], "created",
              comment: "created #{record['benefit_type']} request_issue",
              relevant_data_keys: RELEVANT_DATA_KEYS)
  end

  def request_issue_closed_event
    new_event(record["closed_at"], "closed",
              comment: "request_issue #{record['closed_status']}")
  end
end
