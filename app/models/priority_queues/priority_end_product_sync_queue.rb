# frozen_string_literal: true

# Model for Priority End Product Sync Queue table.
# This table consists of records of End Product Establishment IDs that need to be synced with VBMS.
class PriorityEndProductSyncQueue < CaseflowRecord
  self.table_name = "priority_end_product_sync_queue"

  belongs_to :end_product_establishment
end
