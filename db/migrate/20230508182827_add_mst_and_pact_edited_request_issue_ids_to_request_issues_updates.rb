class AddMstAndPactEditedRequestIssueIdsToRequestIssuesUpdates < Caseflow::Migration
  def change
    add_column :request_issues_updates, :mst_edited_request_issue_ids, :integer, comment: "An array of the request issue IDs that were updated to be associated with MST in request issues update", array: true
    add_column :request_issues_updates, :pact_edited_request_issue_ids, :integer, comment: "An array of the request issue IDs that were updated to be associated with PACT in request issues update", array: true
  end
end
