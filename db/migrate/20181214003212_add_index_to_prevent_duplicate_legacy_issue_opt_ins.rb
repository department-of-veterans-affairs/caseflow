class AddIndexToPreventDuplicateLegacyIssueOptIns < ActiveRecord::Migration[5.1]
disable_ddl_transaction!
  def change
    add_index :legacy_issue_optins, [:vacols_id, :vacols_sequence_id], algorithm: :concurrently, name: 'unique_index_to_avoid_duplicate_opt_ins', where: "rollback_processed_at is NULL", unique: true
  end
end
