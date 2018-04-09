class AddSourceIssueIdToRampIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_issues, :source_issue_id, :integer
  end
end
