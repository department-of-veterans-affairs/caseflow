# frozen_string_literal: true

class PriorityEpSyncBatchProcess < BatchProcess
  class << self
    # Purpose: Finds records to batch from the Priority End Product Sync Queue (PEPSQ) table that
    # have NO batch_id OR have a batch_id tied to a COMPLETED Batch Process (BATCHABLE),
    # do NOT have a status of SYNCED OR STUCK (SYNCABLE),
    # and have a last_batched_at date/time that is NULL OR greater than the ERROR_DELAY (READY_TO_BATCH).
    #
    # Params: None
    #
    # Response: PEPSQ records
    def find_records_to_batch
      PriorityEndProductSyncQueue.batchable.syncable.ready_to_batch.batch_limit
    end

    # Purpose: Creates a Batch Process record and assigns its batch_id
    # to the PEPSQ records gathered by the find_records_to_batch method.
    #
    # Params: Records retrieved from the Priority End Product Sync Queue (PEPSQ) table
    #
    # Response: Newly Created Batch Process
    def create_batch!(records)
      new_batch = PriorityEpSyncBatchProcess.create!(batch_type: name,
                                                     state: Constants.BATCH_PROCESS.pre_processing,
                                                     records_attempted: records.count)

      new_batch.assign_batch_to_queued_records!(records)
      new_batch
    end
  end

  # Purpose: Updates the Batch Process status to processing then loops through each record within
  # the batch. Each record's status is updated to processing, then the #sync! method is attempted.
  # If the record fails, the error_out_record! method is called.
  #
  # Params: None
  #
  # Response: Returns True if batch is processed successfully
  # rubocop:disable Metrics/MethodLength
  def process_batch!
    batch_processing!

    priority_end_product_sync_queue.each do |record|
      record.status_processing!
      epe = record.end_product_establishment

      begin
        epe.sync!
        epe.reload

        if epe.vbms_ext_claim.nil?
          fail Caseflow::Error::PriorityEndProductSyncError, "Claim ID: #{epe.reference_id} not In VBMS_EXT_CLAIM."
        elsif epe.synced_status != epe.vbms_ext_claim&.level_status_code
          fail Caseflow::Error::PriorityEndProductSyncError, "EPE ID: #{epe&.id}.  EPE synced_status of"\
           " #{epe.synced_status} does not match the VBMS_EXT_CLAIM level_status_code of"\
           " #{epe.vbms_ext_claim&.level_status_code}."
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
  # rubocop:enable Metrics/MethodLength

  # Purpose: Assigns the Batch Process batch_id to Priority End Product Sync Queue (PEPSQ) records.
  #
  # Params: Records retrieved from the Priority End Product Sync Queue (PEPSQ) table
  #
  # Response: Newly batched PEPSQ records
  def assign_batch_to_queued_records!(records)
    records.each do |pepsq_record|
      pepsq_record.update!(batch_id: batch_id,
                           status: Constants.PRIORITY_EP_SYNC.pre_processing,
                           last_batched_at: Time.zone.now)
    end
  end
end
