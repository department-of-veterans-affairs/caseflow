class CreatePriorityEndProductSyncQueue < Caseflow::Migration
  def change
    create_table :priority_end_product_sync_queue, comment: "Queue of End Product Establishments that need to sync with VBMS" do |t|
      t.integer :end_product_establishment_id, unique: true, null: false, comment: "ID of end_product_establishment record to be synced"
      t.uuid :batch_id, null: false, comment: "A unique UUID for the batch the record is executed with"
      t.string :status, null: false, default: "PENDING", comment: "A status to indicate what state the record is in such as PROCESSING and PROCESSED"
      t.timestamp :created_at, null: false, comment: "Date and Time the record was inserted into the queue"
      t.timestamp :last_batched_at, null: true, comment: "Date and Time the record was last batched"
      t.string :error_messages, array: true, default: [], comment: "Array of Error Message(s) containing Batch ID and specific error if a failure occurs"
    end
  end
end
