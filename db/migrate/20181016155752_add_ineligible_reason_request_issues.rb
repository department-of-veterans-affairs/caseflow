class AddIneligibleReasonRequestIssues < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :request_issues, :ineligible_reason, :integer
    add_column :request_issues, :ineligible_request_issue_id, :bigint
    safety_assured { add_index :request_issues, :ineligible_reason }
    safety_assured { add_index :request_issues, :ineligible_request_issue_id }
  end
end
