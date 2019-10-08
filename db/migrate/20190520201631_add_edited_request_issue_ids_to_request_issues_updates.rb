class AddEditedRequestIssueIdsToRequestIssuesUpdates < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues_updates, :edited_request_issue_ids, :integer, array: true, comment: "An array of the request issue IDs that were edited during this request issues update"
  end
end
