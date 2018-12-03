class AddDecisionIssueIdToRemandReasons < ActiveRecord::Migration[5.1]

  def change
  	add_column :remand_reasons, :decision_issue_id, :integer
  end
end
