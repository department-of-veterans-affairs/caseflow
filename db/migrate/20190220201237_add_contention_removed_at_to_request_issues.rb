class AddContentionRemovedAtToRequestIssues < ActiveRecord::Migration[5.1]
  def up
  	add_column :request_issues, :contention_removed_at, :datetime
  	safety_assured do
  	  execute "UPDATE request_issues SET contention_removed_at=removed_at"
	  end
  end

  def down
  	remove_column :request_issues, :contention_removed_at
  end
end
