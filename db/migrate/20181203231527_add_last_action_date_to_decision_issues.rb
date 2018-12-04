class AddLastActionDateToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :last_action_date, :date
  end
end
