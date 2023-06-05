
# The records that appear here are records that have attempted multiple times
# to sync or be processed in some way but have continuly errored out. These records
# are intened to be checked and fixed manually.

class CaseflowStuckRecords < CaseflowRecord

  belongs_to :stuck_record, polymorphic: true
  # When we have access to the other models we need to add the code below to each
    # has_one :column_name_of_polymorphic_id, as: :stuck_record
    # ^ 'has_one' might need to change depending on the model



  def report_stuck_record(record)

  end

end
