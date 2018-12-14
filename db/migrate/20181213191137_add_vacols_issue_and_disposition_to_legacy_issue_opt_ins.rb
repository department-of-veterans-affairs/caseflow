class AddVacolsIssueAndDispositionToLegacyIssueOptIns < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :legacy_issue_optins, :vacols_id, :string
    add_column :legacy_issue_optins, :vacols_sequence_id, :integer
    change_column :request_issues, :vacols_sequence_id, :integer, using: 'vacols_sequence_id::integer'
    add_column :legacy_issue_optins, :original_disposition_code, :string
    add_column :legacy_issue_optins, :original_disposition_date, :date
    add_column :legacy_issue_optins, :optin_processed_at, :datetime
    add_column :legacy_issue_optins, :rollback_created_at, :datetime
    add_column :legacy_issue_optins, :rollback_processed_at, :datetime
    remove_column :legacy_issue_optins, :submitted_at, :datetime
    remove_column :legacy_issue_optins, :attempted_at, :datetime
    remove_column :legacy_issue_optins, :processed_at, :datetime
  end
end
