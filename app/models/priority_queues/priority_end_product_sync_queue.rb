# frozen_string_literal: true

class PriorityEndProductSyncQueue < CaseflowRecord
  self.table_name = "priority_end_product_sync_queue"

  belongs_to :end_product_establishment
end
