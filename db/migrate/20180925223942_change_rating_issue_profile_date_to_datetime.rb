class ChangeRatingIssueProfileDateToDatetime < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    change_column :request_issues, :rating_issue_profile_date, :datetime
  end
end
