class AddRequestIssuesUpdateTimestamps < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues_updates, :created_at, :datetime, comment: "Timestamp when record was initially created"
    add_column :request_issues_updates, :updated_at, :datetime, comment: "Timestamp when record was last updated."
  end
end
