class AddContestedRatingIssueColumnsToRequestIssue < ActiveRecord::Migration[5.1]
  def change
  	add_reference :request_issues, :decision_review, index: { name: "index_request_issues_on_decision_review_columns"}, polymorphic: true
  	add_column :request_issues, :contested_rating_issue_reference_id, :string
  	add_column :request_issues, :contested_rating_issue_profile_date, :string
  	add_column :request_issues, :contested_rating_issue_description, :string
  end
end
