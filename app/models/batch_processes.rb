# Public: The BatchProcesses model is responsible for creating and processing batches within
# caselfow. Since the batch_processes table and model are for general use and batching between
# types won't be the same, how batches are created and how they are processed are handled by
# individual private methods.
#
# Methods for batching should follow the convention of "batch_" followed by the type
class BatchProcess < CaseflowRecord

  has_many :priority_end_product_sync_queue


  # This method checks the priority_end_product_sync_queue table and begin creating a batch.
  # After creation the method will call the appropriate processing method.
  #
  # Returns the batch_id created of the batch that is formed.
  def batch_priority_end_product_sync
    records = []
    batch_limit = 100 # Number of total possible records in a batch
    error_delay = 12 # Delay, in hours, before an errored out record will try and be synced again
    max_errors = 3 # Number of errors before declaring stuck

    uuid = SecureRandom.uuid
    while BatchProcess.find(batch_id: uuid)
      uuid = SecureRandom.uuid
    end

    new_batch = BatchProcess.create!(batch_id: uuid
                                     state: "CREATING_BATCH",
                                     batch_type: "priority_end_product_sync")

    PriorityEndProductSyncQueue.where(batch_id: nil).limit(batch_limit).each do |r|
      if r.last_batched_at >= error_delay.hours.ago
        r.update!(batch_id: new_batch.batch_id, state: "PRE_PROCESSING")
        records.push(r)
      end
    end

    new_batch.update!(state: "PRE_PROCESSING", records_attempted: records.length)
  end


  # This method is responsible for finding 'priority_end_product_sync' batches that have
  # yet to be processed and process them.
  def process_priority_end_product_sync
    processing_batch = BatchProcess.first(batch_type: 'priority_end_product_sync',
                                          state: 'PRE_PROCESSING')

    return unless processing_batch != nil

    completed = 0
    failed = 0
    processing_batch.update!(state: 'PROCESSING')
    PriorityEndProductSyncQueue.where(batch_id: processing_batch.batch_id).each do |r|
      r.update!(status: 'PROCESSING')

      # Call EndProductSyncJob.preform and try to sync the process
      # If passes, completed++. Otherwise failed++ and update record
      #
      begin
        r.end_product_establishment.sync! #sync_status matach level status code
        r.end_product_establishment.reload
        r_in_vbms = VbmsExtClaim.find_by(CLAIM_ID: r.end_product_establishment.reference_id)

        if r.sync_status != r_in_vbms.level_status_code
          fail ProcessingPriorityEndProductSyncError, "#{Time.zone.now}"

        else
          completed+=1
          r.update!(state: 'SYNCED')
        end

      rescue Errno::ETIMEDOUT => error
        raise error

      rescue ProcessingPriorityEndProductSyncError => error
        error_out_record(r, error)
        failed+=1
        capture_exception(error: error, extra: {batch_id: batch_id})
        next

      rescue StandardError => error
        error_out_record(r, error)
        failed+=1
        capture_exception(error: error, extra: {batch_id: batch_id})
        next
      end #Begin/Rescue
    end # .where.each

    processing_batch.update!(state: "COMPLETED",
                             records_failed: failed,
                             records_completed: completed,
                             ended_at: Time.zone.now)
  end

  private

  def error_out_record(rec, error)
    error_array = rec.error_messages
    error_array.push("BatchID: "+rec.batch_id+" - "+error.inspect)
    if(error_array.length >= 3) # CHANGE hard coded value after env setup
      rec.update!(state: "STUCK", error_messages: error_array)
      declare_record_stuck(rec)
    else
      rec.update!(batch_id: nil,
                  last_batched_at: nil,
                  state: 'ERROR',
                  error_messages: error_array)
    end
  end

  # This method will move the record out of whatever queue or table it's in and
  # then tranfers it to the caseflow_stuck_records table while calling
  # necessary visable error handling. (Raven, slack, etc..)

  def declare_record_stuck(record)
    #APPEALS-22704 required

  end



end
