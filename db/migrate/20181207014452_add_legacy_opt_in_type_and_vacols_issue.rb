class AddLegacyOptInTypeAndVacolsIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :vacols_issue, :json
    add_column :legacy_issue_optins, :action, :string
    add_column :legacy_issue_optins, :original_appeal, :json
  end
end
