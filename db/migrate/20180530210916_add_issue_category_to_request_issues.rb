class AddIssueCategoryToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :issue_category, :string
    change_column_null :request_issues, :rating_issue_reference_id, true
    change_column_null :request_issues, :rating_issue_profile_date, true
  end
end
