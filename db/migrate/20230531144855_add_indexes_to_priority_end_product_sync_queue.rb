class AddIndexesToPriorityEndProductSyncQueue < Caseflow::Migration
  def change
    add_safe_index :priority_end_product_sync_queue, [:end_product_establishment_id], name: "index_priority_end_product_sync_queue_on_epe_id", unique: true
    add_safe_index :priority_end_product_sync_queue, [:batch_id], name: "index_priority_end_product_sync_queue_on_batch_id", unique: false
  end
end
