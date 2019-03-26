class BoardGrantEffectuationComments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:board_grant_effectuations, "Tracks all the effects of a Board Grant decision made in Caseflow.")
    change_column_comment(:board_grant_effectuations, :appeal_id, "The ID of the appeal containing the granted issue being effectuated.")
    change_column_comment(:board_grant_effectuations, :contention_reference_id, "The ID of the contention created in VBMS. Indicates successful creation of the contention. If the EP has been rated, this contention could have been connected to a rating issue. That connection is used to map the rating issue back to the decision issue.")
    change_column_comment(:board_grant_effectuations, :decision_document_id, "The ID of the decision document which triggered this effectuation.")
    change_column_comment(:board_grant_effectuations, :decision_sync_attempted_at, "When the EP is cleared, an asyncronous job attempts to map the resulting rating issue back to the decision issue. Timestamp representing the time the job was last attempted.")
    change_column_comment(:board_grant_effectuations, :decision_sync_error, "Async job processing last error message. See description for decision_sync_attempted_at for the decision sync job description.")
    change_column_comment(:board_grant_effectuations, :decision_sync_processed_at, "Async job processing completed timestamp. See description for decision_sync_attempted_at for the decision sync job description.")
    change_column_comment(:board_grant_effectuations, :decision_sync_submitted_at, "Async job processing start timestamp. See description for decision_sync_attempted_at for the decision sync job description.")
    change_column_comment(:board_grant_effectuations, :end_product_establishment_id, "The ID of the end product establishment created for this board grant effectuation.")
    change_column_comment(:board_grant_effectuations, :granted_decision_issue_id, "The ID of the granted decision issue.")
    change_column_comment(:board_grant_effectuations, :last_submitted_at, "Async job processing most recent start timestamp (TODO rename)")
  end
end
