class AddWithdrawnIssuesToRequestIssuesUpdate < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues_updates, :withdrawn_request_issue_ids, :integer, array: true, comment: 'An array of the request issue IDs that were withdrawn during this request issues update.'
  end
end
