class AddContentionUpdatedAtToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :contention_updated_at, :datetime, comment: "Timestamp indicating when a contention was successfully updated in VBMS."
  end
end
