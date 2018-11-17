class RemoveNullConstraintDecisionIssueRatingRefId < ActiveRecord::Migration[5.1]
  def change
    change_column_null :decision_issues, :rating_issue_reference_id, true
  end
end
