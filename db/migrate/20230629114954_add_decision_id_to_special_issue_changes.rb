class AddDecisionIdToSpecialIssueChanges < ActiveRecord::Migration[5.2]
  def change
    add_column :special_issue_changes, :decision_issue_id, :bigint, null: true, comment: "ID of the decision issue that had a special issue change from its corresponding request issue"
  end
end
