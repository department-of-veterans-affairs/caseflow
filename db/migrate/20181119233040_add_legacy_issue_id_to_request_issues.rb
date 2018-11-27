class AddLegacyIssueIdToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :vacols_id, :string
    add_column :request_issues, :vacols_sequence_id, :string
  end
end
