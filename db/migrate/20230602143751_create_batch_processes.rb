class CreateBatchProcesses < Caseflow::Migration
  def change
    create_table :batch_processes, id: false, comment: "A generalized table for batching and processing records within caseflow" do |t|
      t.uuid :batch_id, primary_key: true, unique: true, null: false, comment: "The unique id of the created batch"
      t.string :state, default: "PRE_PROCESSING", null: false, comment: "The state that the batch is currently in. PRE_PROCESSING, PROCESSING, PROCESSED"
      t.string :batch_type, null: false, comment: "Indicates what type of record is being batched"
      t.timestamp :started_at, comment: "The date/time that the batch began processing"
      t.timestamp :ended_at, comment: "The date/time that the batch finsished processing"
      t.integer :records_attempted, default: 0, comment: "The number of records in the batch attempting to be processed"
      t.integer :records_completed, default: 0, comment: "The number of records in the batch that completed processing successfully"
      t.integer :records_failed, default: 0, comment: "The number of records in the batch that failed processing"
    end
  end
end
