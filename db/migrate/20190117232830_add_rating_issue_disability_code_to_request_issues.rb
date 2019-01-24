class AddRatingIssueDisabilityCodeToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :contested_rating_issue_disability_code, :string
  end
end
