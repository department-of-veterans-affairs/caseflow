# This table consists of records that have repeatedly attempted
# to sync or be processed in some way but have continuously errored out.
# This table is polymorphic, records on this table could belong to more than one table.
# Records on this table are intended to be checked and fixed manually.

class CaseflowStuckRecord < CaseflowRecord
  belongs_to :stuck_record, polymorphic: true
  # When we have access to the PriorityEndProductSyncQueue model, we need to add the code below
  # has_one :caseflow_stuck_records, as: :stuck_record
  # has_one vs has_many might change depending on the model

  # This method will report the stuck record to the appropriate places upon insertion e.g. slack channels
  # Params: Could be a PriorityEndProductSyncQueue record or any other table's record that has a 'has_one' or 'has_many' association.
  def report_stuck_record(record)
    # Method skeleton
  end
end
