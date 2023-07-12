# frozen_string_literal: true

class BatchProcessPriorityEpSync < BatchProcess
  class << self
    # Finds the records within the PEPSQ table that need to be batched and returns
    # a total number of records equal to the BATCH_LIMIT constant
    def find_records
      PriorityEndProductSyncQueue.completed_or_unbatched.not_synced_or_stuck.batchable.batch_limit.lock
    end

    # This method takes the records from find_records as an agrument.
    # Creates a new batch record within the batch_processes table. Then the batch
    # information is assigned to each record. Returns the newly created batch record.
    def create_batch!(records)
      new_batch = BatchProcessPriorityEpSync.create!(batch_type: name,
                                                     state: Constants.BATCH_PROCESS.pre_processing,
                                                     records_attempted: records.count)

      new_batch.assign_batch_to_queued_records!(records)
      new_batch
    end
  end

  # Updates the batches status to processing then loops through each record within
  # the batch. Each records status is updated to processing, then the sync! method is
  # attempted. If the record fails, the error_out_record! method is called.
  def process_batch!
    batch_processing!

    priority_end_product_sync_queue.each do |record|
      record.status_processing!
      epe = record.end_product_establishment

      begin
        epe.sync!
        epe.reload

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

  # Assigns the batch_id (line 20) to every record that needs to be associated with the batch
  def assign_batch_to_queued_records!(records)
    records.each do |pepsq_record|
      pepsq_record.update!(batch_id: batch_id,
                           status: Constants.PRIORITY_EP_SYNC.pre_processing,
                           last_batched_at: Time.zone.now)
    end
  end
end
