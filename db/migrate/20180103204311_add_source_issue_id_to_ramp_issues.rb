class AddSourceIssueIdToRampIssues < ActiveRecord::Migration
  def change
    add_column :ramp_issues, :source_issue_id, :integer
  end
end
