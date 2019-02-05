class AddClosedAtToRequestIssues < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      add_column :request_issues, :closed_at, :datetime
      add_column :request_issues, :closed_status, :string
      now = Time.zone.now
      execute "UPDATE request_issues SET closed_at = '#{now}', closed_status = 'removed' WHERE review_request_id IS NULL"
    end
  end

  def down
    remove_column :request_issues, :closed_at
    remove_column :request_issues, :closed_status
  end
end
