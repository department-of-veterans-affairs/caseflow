class RemoveSpecialIssueChangesNotNull < ActiveRecord::Migration[6.0]
  def up
    change_column_null(:special_issue_changes, :original_mst_status, true)
    change_column_null(:special_issue_changes, :original_pact_status, true)
  end

  def down
    change_column_null(:special_issue_changes, :original_mst_status, false, false)
    change_column_null(:special_issue_changes, :original_pact_status, false, false)
  end
end
