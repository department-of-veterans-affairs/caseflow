class AddContestedRatingIssueReferenceIdIndex < ActiveRecord::Migration[5.1]
  def change
  	safety_assured { add_index(:request_issues, :contested_rating_issue_reference_id) }
  end
end
