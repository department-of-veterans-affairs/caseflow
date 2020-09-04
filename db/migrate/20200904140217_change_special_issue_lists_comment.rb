class ChangeSpecialIssueListsComment < ActiveRecord::Migration[5.2]
  def change
    change_table_comment :special_issue_lists, "Associates special issues to an AMA or legacy appeal for Queue. Caseflow Dispatch uses special issues stored in legacy_appeals."
  end
end
