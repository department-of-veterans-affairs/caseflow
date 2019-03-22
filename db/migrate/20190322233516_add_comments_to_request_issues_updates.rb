class AddCommentsToRequestIssuesUpdates < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:request_issues_updates, "Keeps track of edits to request_issues on a Decision Review that happen after the initial intake, such as removing and adding issues.  When the Decision Review is processed in VBMS, this keeps track of whether adding or removing contentions in VBMS for the update has succeeded.")

    change_column_comment(:request_issues_updates, :after_request_issue_ids, "An array of the Request Issue IDs after a user has finished editing a Decision Review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added).")

    change_column_comment(:request_issues_updates, :attempted_at, "Timestamp for when the request issue update was last attempted.")

    change_column_comment(:request_issues_updates, :before_request_issue_ids, "An array of the Request Issue IDs previously on the Decision Review before this editing session. Used with after_request_issue_ids to determine appropriate actions (such as which contentions need to be removed).")

    change_column_comment(:request_issues_updates, :error, "If the last attempt at updating the request issues was not successful, the error that we received from VBMS.")

    change_column_comment(:request_issues_updates, :last_submitted_at, "Timestamp for when the the job is eligible to run (can be reset to restart the job).")

    change_column_comment(:request_issues_updates, :processed_at, "Timestamp for when the request issue updated successfully completed processing.")

    change_column_comment(:request_issues_updates, :review_id, "The ID of the Decision Review that was edited.")

    change_column_comment(:request_issues_updates, :review_type, "The type of the Decision Review that was edited.")

    change_column_comment(:request_issues_updates, :submitted_at, "Timestamp for when the update was originally submitted.")

    change_column_comment(:request_issues_updates, :user_id, "The ID of the user who edited the Decision Review.")
  end
end
