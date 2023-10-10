class AddDecisionDateAddedAtToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :decision_date_added_at, :datetime
  end
end
