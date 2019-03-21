class AddStatusColumnToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
  	add_column :decision_issues, :deleted_at, :datetime
  	add_column :request_decision_issues, :deleted_at, :datetime
  	add_column :remand_reasons, :deleted_at, :datetime
  end
end
