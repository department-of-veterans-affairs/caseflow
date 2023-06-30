# frozen_string_literal: true

# Model for Priority End Product Sync Queue table.
# This table consists of records of End Product Establishment IDs that need to be synced with VBMS.
class PriorityEndProductSyncQueue < CaseflowRecord
  self.table_name = "priority_end_product_sync_queue"

  belongs_to :end_product_establishment
  belongs_to :batch_process, foreign_key: "batch_id", primary_key: "batch_id"
  has_one :caseflow_stuck_record, as: :stuck_record

  scope :completed_or_unbatched, -> { where(batch_id: [nil, BatchProcess.completed_batch_process_ids]) }
  scope :batchable, -> { where("last_batched_at IS NULL OR last_batched_at <= ?", BatchProcess::ERROR_DELAY.hours.ago) }
  scope :batch_limit, -> { limit(BatchProcess::BATCH_LIMIT) }
  scope :not_synced_or_stuck, lambda {
    where.not(status: [Constants.PRIORITY_EP_SYNC.synced, Constants.PRIORITY_EP_SYNC.stuck])
  }

  enum status: {
    Constants.PRIORITY_EP_SYNC.not_processed.to_sym => Constants.PRIORITY_EP_SYNC.not_processed,
    Constants.PRIORITY_EP_SYNC.pre_processing.to_sym => Constants.PRIORITY_EP_SYNC.pre_processing,
    Constants.PRIORITY_EP_SYNC.processing.to_sym => Constants.PRIORITY_EP_SYNC.processing,
    Constants.PRIORITY_EP_SYNC.synced.to_sym => Constants.PRIORITY_EP_SYNC.synced,
    Constants.PRIORITY_EP_SYNC.error.to_sym => Constants.PRIORITY_EP_SYNC.error,
    Constants.PRIORITY_EP_SYNC.stuck.to_sym => Constants.PRIORITY_EP_SYNC.stuck
  }


  # Status Update methods
  def status_processing!
    update!(status: Constants.PRIORITY_EP_SYNC.processing)
  end

  def status_sync!
    update!(status: Constants.PRIORITY_EP_SYNC.synced)
  end

  def status_error!(errors)
    update!(status: Constants.PRIORITY_EP_SYNC.error,
            error_messages: errors)
  end

  # Method will update the status of the record to STUCK
  # While also create a record within the caseflow_stuck_records table
  # for later manual review.
  def declare_record_stuck!
    update!(status: Constants.PRIORITY_EP_SYNC.stuck)
    CaseflowStuckRecord.create!(stuck_record: self,
                                error_messages: error_messages,
                                determined_stuck_at: Time.zone.now)

    # ASK Jeremy about other notifiers like Raven.
  end
end
