class AddDtaIdToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :dta_issue_id, :integer, :null => true
  end
end
