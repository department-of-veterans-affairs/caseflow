# frozen_string_literal: true

class BatchProcessPriorityEpSync < BatchProcess
  class << self
    def find_records
      PriorityEndProductSyncQueue.where(
        batch_id: [nil, BatchProcess.where.not("state = ?", "PROCESSING")])
        .where("(status <> ? AND status <> ?) AND
                (last_batched_at IS NULL OR last_batched_at <= ?)",
                Constants.PRIORITY_EP_SYNC.synced,
                Constants.PRIORITY_EP_SYNC.stuck,
                BatchProcess::ERROR_DELAY.hours.ago).lock.limit(BatchProcess::BATCH_LIMIT)

    end


    def create_batch!(records)
      new_batch = BatchProcessPriorityEpSync.create!(batch_type: name,
                                                     state: Constants.BATCH_PROCESS.pre_processing,
                                                     records_attempted: records.count)

      new_batch.assign_batch_to_queued_records!(records)
      new_batch
    end
  end


  def process_batch!
    batch_processing!
    priority_end_product_sync_queue.each do |record|
      record.status_processing!
      epe = record.end_product_establishment

      begin
        epe.sync!

        if epe.vbms_ext_claim.nil?
          fail Caseflow::Error::PriorityEndProductSyncError, "Claim Not In VBMS_EXT_CLAIM."

        elsif epe.synced_status != epe.vbms_ext_claim&.level_status_code
          fail Caseflow::Error::PriorityEndProductSyncError, "EPE synced_status does not match VBMS."
        end

      rescue StandardError => error
        error_out_record!(record, error)
        next
      end

      record.status_sync!
      increment_completed
    end

    batch_complete!
  end


  def assign_batch_to_queued_records!(records)
    records.update_all(batch_id: batch_id,
                                status: Constants.PRIORITY_EP_SYNC.pre_processing,
                                last_batched_at: Time.zone.now)

  end
end
