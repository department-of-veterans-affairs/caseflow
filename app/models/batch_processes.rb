


class BatchProcesses < CaseflowRecord

  # has_many :priority_end_product_sync_queue



  def create_and_process_batch(type)
    case type

		when "priority_end_product_sync"
			return BatchProcesses.batch_priority_end_product_sync

		else
			#Error Handling

  end


  private

  def batch_priority_end_product_sync
    # Check APPEALS-22705 refinment


  end

  def declare_record_stuck
    #APPEALS-22704 required

    # This method will move the record out of whatever queue or table it's in and
    # then tranfers it to the caseflow_stuck_records table while calling
    # necessary visable error handling. (Raven, slack, etc..)

  end

end
