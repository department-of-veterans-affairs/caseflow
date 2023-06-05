

class CreateCaseflowStuckRecords < Caseflow::Migration
  def change
    create_table :caseflow_stuck_records do |t|
      t.references :stuck_record, polymorphic: true, index: { name: 'index_caseflow_stuck_records_on_stuck_record_id_and_type' }, null: false, comment: "The id / primary key of the stuck record and the type / where the record came from"
      t.string :error_messages, array: true, default: [], comment: "Array of Error Message(s) containing Batch ID and specific error if a failure occurs"
      t.timestamp :determined_stuck_at, null: false, comment: "The date/time at which the record in question was determined to be stuck."
    end
  end
end
