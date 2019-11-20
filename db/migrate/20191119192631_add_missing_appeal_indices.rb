class AddMissingAppealIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :claims_folder_searches, [:appeal_id, :appeal_type], algorithm: :concurrently
  end
end
