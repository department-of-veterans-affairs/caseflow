class AddDecisionDateAddedAtToRequestIssues < Caseflow::Migration
  def change
    add_column :request_issues, :decision_date_added_at, :datetime, comment: "Denotes when a decision date was added"
  end
end
