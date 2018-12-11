class AddLegacyOptInTypeAndVacolsIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :legacy_issue_optins, :action, :string
    add_column :legacy_issue_optins, :vacols_id, :string
    add_column :legacy_issue_optins, :vacols_sequence_id, :integer
    add_column :legacy_issue_optins, :previous_disposition_code, :string
    add_column :legacy_issue_optins, :previous_disposition_date, :date
    add_column :legacy_issue_optins, :previous_appeal, :json
  end
end
