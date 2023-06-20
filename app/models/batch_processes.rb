# Public: The BatchProcesses model is responsible for creating and processing batches within
# caselfow. Since the batch_processes table and model are for general use and batching between
# types won't be the same, how batches are created and how they are processed are handled by
# individual private methods.
#
# Methods for batching should follow the convention of "batch_" followed by the type
class BatchProcess < CaseflowRecord

  has_many :priority_end_product_sync_queue


  # Calls the associated private method responible for creating and processing
  # batches based on the type.
  #
  # Args - The type of batch that needs to be created and processed.
  # Return - The resulting batch_id created when the batch is formed.
  def create_and_process_batch(type)
    case type

		when "priority_end_product_sync"
			return BatchProcesses.batch_priority_end_product_sync

		else
			#Error Handling

    end
  end


  private


  # This method checks the priority_end_product_sync_queue table and begin creating a batch.
  # After creation the method will call the appropriate processing method.
  #
  # Returns the batch_id created of the batch that is formed.
  def batch_priority_end_product_sync
    records = []
    batch_limit = 100 # Of records in a batch
    error_delay = 12 # Delay, in hours, before an errored out record will try and be synced again
    max_errors = 3 # Number of errors before declaring stuck
    new_batch = BatchProcess.create(state: "CREATING_BATCH",
                                    batch_type: "priority_end_product_sync")

    # Add next in queue to the batch if no errors, error hasn't occured recently, and isn't stuck
    PriorityEndProductSyncQueue.where(batch_id: nil).limit(batch_limit).each do |r|
      if r.error_messages.length == 0
        r.update(batch_id: new_batch.batch_id)
        records.push(r)

      elsif r.error_messages < max_errors
        if r.last_batched_at >= error_delay.hours.ago
          r.update(batch_id: new_batch.batch_id)
          records.push(r)
        end

      else
        declare_record_stuck(r)
      end
    end # .where.each

    new_batch.update(state: "PRE_PROCESSING", records_attempted: records.length)
  end

  def process_priority_end_product_sync(records)
      # Talk about when we want to be calling this
      # Refinement APPEALS 22705

      # batches that have type: "pepsq" and state: "PRE_PROCESSING"
  end


  # This method will move the record out of whatever queue or table it's in and
  # then tranfers it to the caseflow_stuck_records table while calling
  # necessary visable error handling. (Raven, slack, etc..)
  def declare_record_stuck(record)
    #APPEALS-22704 required

  end

end
