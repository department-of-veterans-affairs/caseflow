class AddCaseflowDecisionDateToDecisionIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :caseflow_decision_date, :date
  end
end
