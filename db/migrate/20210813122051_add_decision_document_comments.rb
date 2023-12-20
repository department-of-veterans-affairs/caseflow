class AddDecisionDocumentComments < Caseflow::Migration
  def change
    # Comments copied from asyncable.rb
    change_column_comment(:decision_documents, "attempted_at", "When the job ran")
    change_column_comment(:decision_documents, "submitted_at", "When the job first became eligible to run")
    change_column_comment(:decision_documents, "last_submitted_at", "When the job is eligible to run (can be reset to restart the job)")
    change_column_comment(:decision_documents, "processed_at", "When the job has concluded")
    change_column_comment(:decision_documents, "error", "Message captured from a failed attempt")

    change_column_comment(:decision_documents, "uploaded_to_vbms_at", "When document was successfully uploaded to VBMS")
    change_column_comment(:decision_documents, "citation_number", "Unique identifier for decision document")
  end
end
