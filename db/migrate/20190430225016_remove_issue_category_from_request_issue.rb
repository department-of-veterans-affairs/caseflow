class RemoveIssueCategoryFromRequestIssue < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :request_issues, :issue_category, :string }
  end
end
