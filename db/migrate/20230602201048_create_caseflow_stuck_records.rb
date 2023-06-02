

class CreateCaseflowStuckRecords < Caseflow::Migration
  def change
    create_table :caseflow_stuck_records do |t|
      t.references :record_id, polymorphic: true, null: false, comment: "The id / primary key of the stuck record"
      t.string :record_type, null: false, comment: "The type of the stuck record / where the record originated from"
      t.string :error_messages, array: true, default: [], comment: "Array of Error Message(s) containing Batch ID and specific error if a failure occurs"
      t.timestamp :determined_stuck_at, null: false, comment: "The date/time at which the record in question was determined to be stuck."
    end
  end
end
