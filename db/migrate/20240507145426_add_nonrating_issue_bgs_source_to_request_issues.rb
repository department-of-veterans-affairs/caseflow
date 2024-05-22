class AddNonratingIssueBgsSourceToRequestIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :request_issues, :nonrating_issue_bgs_source, :string, comment: "Name of Table in Corporate Database where the nonrating issue is stored. This datapoint is correlated with the nonrating_issue_bgs_id."
  end
end
