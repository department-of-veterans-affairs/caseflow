class AddCreatedAtTimestampToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :created_at, :datetime
  end
end
