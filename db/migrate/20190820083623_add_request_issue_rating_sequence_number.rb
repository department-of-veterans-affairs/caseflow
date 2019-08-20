class AddRequestIssueRatingSequenceNumber < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :contested_rating_issue_sequence_id, :string, comment: "The BGS rating_sequence_number for contested issues."
  end
end
