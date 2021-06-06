# frozen_string_literal: true

##
# Maps DecisionDocument records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::DecisionDocumentRecordToEventMapper < Explain::RecordToEventMapper
  # :reek:FeatureEnvy
  def initialize(record)
    super("document", record,
          default_context_id: "#{record['appeal_type']}_#{record['appeal_id']}",
          default_object_id: "DecisionDocument_#{record['id']}")
  end

  def events
    [
      decision_document_submitted_event,
      (decision_document_processed_event if record["processed_at"])
    ].compact
  end

  private

  def decision_document_submitted_event
    relevant_data_keys = %w[attempted_at canceled_at last_submitted_at
                            decision_date redacted_document_location error].freeze
    new_event(record["submitted_at"], "submitted",
              comment: "submitted decision_document #{record['citation_number']}",
              relevant_data_keys: relevant_data_keys)
  end

  def decision_document_processed_event
    new_event(record["processed_at"], "processed",
              comment: "submitted decision_document #{record['citation_number']}",
              relevant_data_keys: %w[uploaded_to_vbms_at])
  end
end
