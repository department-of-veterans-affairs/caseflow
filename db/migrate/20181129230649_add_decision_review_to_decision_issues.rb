class AddDecisionReviewToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :decision_review_type, :string
    add_column :decision_issues, :decision_review_id, :integer
  end
end
