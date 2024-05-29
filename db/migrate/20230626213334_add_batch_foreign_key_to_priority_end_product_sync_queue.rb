class AddBatchForeignKeyToPriorityEndProductSyncQueue < Caseflow::Migration
  def change
    add_foreign_key :priority_end_product_sync_queue, :batch_processes, column: "batch_id", primary_key: "batch_id", name: "priority_end_product_sync_queue_batch_processes_id_fk", validate: false
  end
end
