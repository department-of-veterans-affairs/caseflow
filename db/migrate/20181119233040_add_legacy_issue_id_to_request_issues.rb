class AddLegacyIssueIdToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :vacols_id, :integer
  end
end
