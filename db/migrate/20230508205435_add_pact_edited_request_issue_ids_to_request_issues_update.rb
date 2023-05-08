class AddPactEditedRequestIssueIdsToRequestIssuesUpdate < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues_updates, :pact_edited_request_issue_ids, :integer, comment: "An array of the request issue IDs that were updated to be associated with PACT in request issues update", array: true
  end
end
