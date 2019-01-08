class AddRequestIssueDescriptionColumns < ActiveRecord::Migration[5.1]
  def change
  	remove_column :request_issues, :contested_rating_issue_description, :string
  	add_column :request_issues, :contested_issue_description, :string
  	add_column :request_issues, :nonrating_issue_description, :string
  	add_column :request_issues, :unidentified_issue_text, :string
  end
end
