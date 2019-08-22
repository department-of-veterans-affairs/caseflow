class AddRequestIssueRatingSequenceNumber < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :contested_rating_decision_reference_id, :string, comment: "The BGS id for contested rating decisions. These may not have corresponding contested_rating_issue_reference_id values."
  end
end
