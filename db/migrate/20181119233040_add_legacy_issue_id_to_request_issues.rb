class AddLegacyIssueIdToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :legacy_issue_id, :integer
    add_column :request_issues, :vacols_sequence_id, :integer
  end
end
