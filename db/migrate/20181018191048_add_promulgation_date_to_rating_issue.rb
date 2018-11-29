class AddPromulgationDateToRatingIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :rating_issues, :promulgation_date, :datetime, null: false
  end
end
