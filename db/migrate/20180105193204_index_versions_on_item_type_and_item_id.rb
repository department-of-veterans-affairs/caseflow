class IndexVersionsOnItemTypeAndItemId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :versions, [:item_type, :item_id], algorithm: :concurrently
  end
end
