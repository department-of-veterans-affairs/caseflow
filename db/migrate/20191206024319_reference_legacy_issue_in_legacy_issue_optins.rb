class ReferenceLegacyIssueInLegacyIssueOptins < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    add_reference :legacy_issue_optins, :legacy_issue, foreign_key: true, comment: "The legacy issue being opted in, which connects to the request issue", index: false
    add_index :legacy_issue_optins, :legacy_issue_id, algorithm: :concurrently

  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
