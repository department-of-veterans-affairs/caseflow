class RemoveUnusedColumnsFromRequestIssues < ActiveRecord::Migration[5.1]
  def change
  	safety_assured do
  	  remove_column :request_issues, :contested_rating_issue_disability_code
  	  remove_column :request_issues, :rating_issue_reference_id
  	  remove_column :request_issues, :rating_issue_profile_date
  	  remove_column :request_issues, :review_request_id
  	  remove_column :request_issues, :review_request_type
  	  remove_column :request_issues, :description
    end
  end
end
