# frozen_string_literal: true

require_relative "batch_process"

class BatchProcessPriorityEpSync < BatchProcess
  class << self
    def find_records_to_batch
      PriorityEndProductSyncQueue.where("batch_id IS NULL AND (last_batched_at IS NULL OR last_batched_at <= ?)",
                                        BatchProcess::ERROR_DELAY.hours.ago).lock.limit(BatchProcess::BATCH_LIMIT)
    end

    def create_batch!
      uuid = SecureRandom.uuid
      BatchProcessPriorityEpSync.create!(batch_id: uuid, batch_type: name)
    end
  end

  def build_batch!(records_to_batch)
    batch_priority_queued_epes!(records_to_batch)
    records_attempted!
    self
  end

  def process_batch!
    process_state!

    priority_end_product_sync_queue.each do |record|
      epe = record.end_product_establishment
      begin
        epe.sync!

        fail Caseflow::Error::PriorityEndProductSyncError, "Claim Not In VBMS_EXT_CLAIM." unless epe.vbms_ext_claim
        if epe.synced_status != epe.vbms_ext_claim&.level_status_code
          fail Caseflow::Error::PriorityEndProductSyncError, "EPE synced_status does not match VBMS."
        end
      rescue StandardError => error
        error_out_record!(record, error)
        next
      end
      record.finished_sync_status!
      increment_completed
    end

    complete_state!
  end

  private

  def batch_priority_queued_epes!(records_to_batch)
    @attempted_count = records_to_batch.count
    records_to_batch.update_all(batch_id: batch_id,
                                status: "PRE_PROCESSING",
                                last_batched_at: Time.zone.now)
  end
end
