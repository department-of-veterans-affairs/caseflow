class AddMissingRequestIssueIndices < Caseflow::Migration
  def change
    add_safe_index :request_issues, [:contested_rating_decision_reference_id]
    add_safe_index :request_issues, [:closed_at]
    add_safe_index :request_issues, [:ineligible_reason]
  end
end
