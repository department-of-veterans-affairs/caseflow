class AddCommentToCaseflowStuckRecords < Caseflow::Migration
  def change
    change_table_comment :caseflow_stuck_records, "This is a polymorphic table consisting of records that have repeatedly errored out of the syncing process. Currently, the only records on this table come from the PriorityEndProductSyncQueue table."
  end
end
