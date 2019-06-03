class AddNonratingIssueCategoryToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :nonrating_issue_category, :string, comment: 'The category selected for nonrating request issues. These vary by business line.'
  end
end
