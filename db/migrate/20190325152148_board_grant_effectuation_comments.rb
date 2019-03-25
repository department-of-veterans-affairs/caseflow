class BoardGrantEffectuationComments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:board_grant_effectuations, "Tracks all the effects of a Board Grant decision made in Caseflow.")
    change_column_comment(:board_grant_effectuations, :appeal_id, "The ID of the Appeal Decision Review connected to this Board Grant Effectuation.")
    change_column_comment(:board_grant_effectuations, :contention_reference_id, "The ID of the contention created in VBMS on the established End Product. Indicates successful creation of the contention.")
    change_column_comment(:board_grant_effectuations, :decision_document_id, "The ID of the Decision Document created as part of outcoding.")
    change_column_comment(:board_grant_effectuations, :decision_sync_attempted_at, "Async job processing last attempted timestamp")
    change_column_comment(:board_grant_effectuations, :decision_sync_error, "Async job processing last error message")
    change_column_comment(:board_grant_effectuations, :decision_sync_processed_at, "Async job processing completed timestamp")
    change_column_comment(:board_grant_effectuations, :decision_sync_submitted_at, "Async job processing start timestamp")
    change_column_comment(:board_grant_effectuations, :end_product_establishment_id, "The ID of the End Product Establishment created for this Board Grant Effectuation.")
    change_column_comment(:board_grant_effectuations, :granted_decision_issue_id, "The ID of the granted decision issue.")
    change_column_comment(:board_grant_effectuations, :last_submitted_at, "Async job processing most recent start timestamp (TODO rename)")
  end
end
