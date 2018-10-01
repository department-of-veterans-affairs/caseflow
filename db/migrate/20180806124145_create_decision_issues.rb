class CreateDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :decision_issues do |t|
    	t.string :disposition
      t.string :disposition_date
      t.string :description
      t.integer :request_issue_id
    end
  end
end
