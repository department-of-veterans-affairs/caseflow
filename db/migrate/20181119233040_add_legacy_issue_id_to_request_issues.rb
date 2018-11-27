class AddLegacyIssueIdToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :legacy_issue_reference_id, :integer
    add_column :request_issues, :legacy_sequence_reference_id, :integer
  end
end
