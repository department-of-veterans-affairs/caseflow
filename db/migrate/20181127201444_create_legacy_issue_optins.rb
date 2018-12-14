class CreateLegacyIssueOptins < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def change
    create_table :legacy_issue_optins do |t|
      t.belongs_to :request_issue, null: false
      t.timestamps null: false
      t.datetime :submitted_at
      t.datetime :attempted_at
      t.datetime :processed_at
      t.string :error
    end
  end
end
