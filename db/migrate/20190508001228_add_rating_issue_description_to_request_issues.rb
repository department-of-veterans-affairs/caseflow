class AddRatingIssueDescriptionToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :rating_issue_description, :string, comment: "Description of the edited contested rating or decision issue. Will be either a rating issue's decision text or a decision issue's description."
  end
end
