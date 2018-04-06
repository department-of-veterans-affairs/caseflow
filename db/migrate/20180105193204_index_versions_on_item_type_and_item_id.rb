class IndexVersionsOnItemTypeAndItemId < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :versions, [:item_type, :item_id], algorithm: :concurrently
  end
end
