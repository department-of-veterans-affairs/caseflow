class AddMissingAppealIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes
    add_index :claims_folder_searches, [:appeal_id, :appeal_type], algorithm: :concurrently
  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
