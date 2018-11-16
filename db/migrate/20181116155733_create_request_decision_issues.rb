class CreateRequestDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :request_decision_issues do |t|
      t.integer :request_issue_id
      t.integer :decision_issue_id
      t.timestamps
    end
  end
end
