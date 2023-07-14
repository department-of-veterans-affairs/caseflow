class AddIndexOnLastBatchedAtAndStatusToPriorityEndProductSyncQueue < Caseflow::Migration
  def change
    add_safe_index :priority_end_product_sync_queue, [:last_batched_at], name: "index_priority_ep_sync_queue_on_last_batched_at", unique: false
    add_safe_index :priority_end_product_sync_queue, [:status], name: "index_priority_ep_sync_queue_on_status", unique: false
  end
end
