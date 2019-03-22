class AddUpdatedAtRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :updated_at, :datetime
  end
end
