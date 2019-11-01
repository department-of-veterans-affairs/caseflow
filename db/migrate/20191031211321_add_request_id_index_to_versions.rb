class AddRequestIdIndexToVersions < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :versions, :request_id, algorithm: :concurrently
  end
end
