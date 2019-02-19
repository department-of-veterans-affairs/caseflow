class AddCreatedAtToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :created_at, :datetime
  end
end
