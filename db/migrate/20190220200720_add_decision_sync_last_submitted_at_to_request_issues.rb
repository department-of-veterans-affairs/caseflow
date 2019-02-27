class AddDecisionSyncLastSubmittedAtToRequestIssues < ActiveRecord::Migration[5.1]
  def up
  	add_column :request_issues, :decision_sync_last_submitted_at, :datetime
  	safety_assured do
  	  execute "UPDATE request_issues SET decision_sync_last_submitted_at=last_submitted_at"
	  end
  end

  def down
  	remove_column :request_issues, :decision_sync_last_submitted_at
  end
end
