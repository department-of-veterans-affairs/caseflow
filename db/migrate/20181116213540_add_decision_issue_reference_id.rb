class AddDecisionIssueReferenceId < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :decision_issue_reference_id, :integer
  end
end
