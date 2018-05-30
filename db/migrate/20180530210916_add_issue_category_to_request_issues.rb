class AddIssueCategoryToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :issue_category, :string
  end
end
