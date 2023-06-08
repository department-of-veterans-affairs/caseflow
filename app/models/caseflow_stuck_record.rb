# Public:
# The records that appear here are records that have attempted multiple times
# to sync or be processed in some way but have continuously errored out.
# This table is polymorphic, instances could belong to different tables.
# The records on this table are intended to be checked and fixed manually.

class CaseflowStuckRecord < CaseflowRecord
  belongs_to :stuck_record, polymorphic: true
  # When we have access to the PriorityEndProductSyncQueue model, we need to add the code below
  # has_one :caseflow_stuck_records, as: :stuck_record
  # has_one vs has_many might change depending on the model

  # This method will report the stuck record to the appropriate places upon insertion e.g. slack channels
  # A record in our case is a PriorityEndProductSyncQueue record
  # But it could be a record from a different table that exists within the batch_processes table
  def report_stuck_record(record)
    # Method skeleton
  end
end
