# frozen_string_literal: true

# Model for Priority End Product Sync Queue table.
# This table consists of records of End Product Establishment IDs that need to be synced with VBMS.
class PriorityEndProductSyncQueue < CaseflowRecord
  self.table_name = "priority_end_product_sync_queue"

  belongs_to :end_product_establishment
  belongs_to :batch_process, foreign_key: "batch_id"
  has_one :caseflow_stuck_records, as: :stuck_record

  def synced_status!
    update!(status: "SYNCED")
  end

  def unbatch!(errors)
    update!(batch_id: nil, status: "ERROR", error_messages: errors)
  end

  def stuck!
    CaseflowStuckRecord.create!(stuck_record: self, error_messages: error_messages, determined_stuck_at: Time.zone.now)
  end
end
