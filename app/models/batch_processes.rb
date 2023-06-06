# Public: The BatchProcesses model is responsible for creating and processing batches within
# caselfow. Since the batch_processes table and model are for general use and batching between
# types won't be the same, how batches are created and how they are processed are handled by
# individual private methods.
#
# Methods for batching should follow the convention of "batch_" followed by the type
class BatchProcesses < CaseflowRecord

  # has_many :priority_end_product_sync_queue


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


  # This method checks the priority_end_product_sync_queue table and begin creating a
  # and processing a batch. Will check associated HLRs and SCs for other EPE's that need
  # to be synced and add all unsynced records to the batch if the limit hasn't been met.
  #
  # Returns the batch_id created when the batch is formed.
  def batch_priority_end_product_sync
    # Check APPEALS-22705 refinment

  end


  # This method will move the record out of whatever queue or table it's in and
  # then tranfers it to the caseflow_stuck_records table while calling
  # necessary visable error handling. (Raven, slack, etc..)
  def declare_record_stuck
    #APPEALS-22704 required

  end

end
