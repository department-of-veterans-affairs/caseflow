class AddReferenceIdIndexToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    safety_assured { add_index(:request_issues, :rating_issue_reference_id) }
  end
end
