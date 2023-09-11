# frozen_string_literal: true

# This table consists of records that have repeatedly attempted
# to sync or be processed in some way but have continuously errored out.
# This table is polymorphic, records on this table could belong to more than one table.
# Records on this table are intended to be checked and fixed manually.

class CaseflowStuckRecord < CaseflowRecord
  belongs_to :stuck_record, polymorphic: true

  # Custom model association that will return the end_product_establishment for
  # stuck records that are from the PriorityEndProductSyncQueue
  def end_product_establishment
    if stuck_record.is_a?(PriorityEndProductSyncQueue)
      stuck_record.end_product_establishment
    end
  end
end
