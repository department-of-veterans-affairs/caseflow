# Public: The BatchProcesses model is responsible for creating and processing batches within
# caselfow. Since the batch_processes table and model are for general use and batching between
# types won't be the same, how batches are created and how they are processed are handled by
# individual private methods.
#
# Methods for batching should follow the convention of "batch_" followed by the type
class BatchProcess < CaseflowRecord

  # This method checks the priority_end_product_sync_queue table and begin creating a batch.
  # After creation the method will call the appropriate processing method.
  #
  # Returns the batch_id created of the batch that is formed.
  def batch_priority_end_product_sync!
    records_batched = 0
    uuid = SecureRandom.uuid
    new_batch = BatchProcess.create!(batch_id: uuid,
                                     state: "CREATING_BATCH",
                                     batch_type: "priority_end_product_sync")

    # Find the records that need batching but also haven't had an error recently
    PriorityEndProductSyncQueue.where(
      "batch_id IS NULL AND
      (last_batched_at IS NULL OR last_batched_at <= ?)",
      ENV["ERROR_DELAY"].to_i.hours.ago).limit(ENV["BATCH_LIMIT"].to_i).each do |rec|
        rec.update!(batch_id: new_batch.batch_id,
                  status: "PRE_PROCESSING",
                  last_batched_at: Time.zone.now)

        records_batched+=1
    end

    new_batch.update!(state: "PRE_PROCESSING", records_attempted: records_batched)
  end


  # This method is responsible for finding 'priority_end_product_sync' batches that have
  # yet to be processed and process them.
  def process_priority_end_product_sync!(processing_batch)
    completed = 0
    failed = 0
    processing_batch.update!(state: 'PROCESSING', started_at: Time.zone.now)

    # Find the batchs records and attempt to sync them
    PriorityEndProductSyncQueue.where(batch_id: processing_batch.batch_id).each do |rec|
      begin
        rec.update!(status: 'PROCESSING')
        epe = rec.end_product_establishment
        epe.sync!
        epe.reload
        vbms_rec = VbmsExtClaim.find_by(claim_id: epe.reference_id.to_i)

        # Check if the EPE was actually synced with VBMS, if it wasn't throw error
        if epe.synced_status != vbms_rec.level_status_code

            fail Caseflow::Error::ProcessingPriorityEndProductSyncError, "EPE Failed to sync at: #{Time.zone.now}"

        else
          completed+=1
          rec.update!(status: 'SYNCED')
        end

      rescue Errno::ETIMEDOUT => error
        error_out_record(rec, error)
        failed+=1
        next

      # When the record still isn't synced after .sync! has been called on it
      rescue Caseflow::Error::ProcessingPriorityEndProductSyncError => error
        error_out_record(rec, error)
        failed+=1
        next

      rescue StandardError => error
        error_out_record(rec, error)
        failed+=1
        Rails.logger.error(error.inspect)
        next

      end # Begin/Rescues/ensure
    end # PEPSQ.where.each

    processing_batch.update!(state: "COMPLETED",
                             records_failed: failed,
                             records_completed: completed,
                             ended_at: Time.zone.now)
  end

  private


  # When a record and error is sent to this method, it updates the record and checks to see
  # if the record should be declared stuck. If the records should be stuck it called the
  # declare_record_stuck method below. Otherwise the record is updated with the error message,
  # and the previous batch information is removed so the record can get picked up in queue again.
  #
  # As a general method, it's assumed the record has a batch_id and error_messages
  # column within the associated table.
  def error_out_record(rec, error)
    error_array = rec.error_messages
    error_array.push("Error: #{error.inspect} - BatchID: #{rec.batch_id} - Time: #{Time.zone.now} ")
    if(error_array.length >= ENV["MAX_ERRORS_BEFORE_STUCK"].to_i)
      rec.update!(status: "STUCK", error_messages: error_array)
      declare_record_stuck(rec)
    else
      rec.update!(batch_id: nil,
                  status: 'ERROR',
                  error_messages: error_array)
    end
  end


  # This method creates a new record within caseflow_stuck_records table
  # based on the record sent to it. The innitial record is not altered.
  # The method will then notify that a record has gotten stuck and needs
  # manual review.
  #
  # As a general method, it's assumed the record has a batch_id and error_messages
  # column within the associated table.
  def declare_record_stuck(rec)
    associated_batch = BatchProcess.find_by(batch_id: rec.batch_id)
    CaseflowStuckRecord.create!(stuck_record_id: rec.id,
                                stuck_record_type: associated_batch.batch_type,
                                error_messages: rec.error_messages,
                                determined_stuck_at: Time.zone.now)

    # NOTIFING CODE - Ask Jeremy what should be notified. Raven / Slack etc...
  end
end
