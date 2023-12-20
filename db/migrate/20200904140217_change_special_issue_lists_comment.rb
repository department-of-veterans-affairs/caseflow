class ChangeSpecialIssueListsComment < ActiveRecord::Migration[5.2]
  def up
    change_table_comment :special_issue_lists, "Associates special issues to an AMA or legacy appeal for Caseflow Queue. Caseflow Dispatch uses special issues stored in legacy_appeals. They are intentionally disconnected."
    change_column_comment :special_issue_lists, :appeal_id, "The ID of the appeal associated with this record"
    change_column_comment :special_issue_lists, :appeal_type, "The type of appeal associated with this record"
  end
  def down
    change_table_comment :special_issue_lists, ""
    change_column_comment :special_issue_lists, :appeal_id, ""
    change_column_comment :special_issue_lists, :appeal_type, ""
  end
end
