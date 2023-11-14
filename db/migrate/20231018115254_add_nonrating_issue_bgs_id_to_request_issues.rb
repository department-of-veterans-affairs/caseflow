class AddNonratingIssueBgsIdToRequestIssues < Caseflow::Migration
  def change
    add_column :request_issues, :nonrating_issue_bgs_id, :string, comment: "If the contested issue is a nonrating issue, this is the nonrating issue's reference id. Will be nil if this request issue contests a decision issue."
  end
end
