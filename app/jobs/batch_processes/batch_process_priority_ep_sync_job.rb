class BatchProcessPriorityEPSyncJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue

  def perform
    begin
      created_batch = BatchProcess.batch_priority_end_product_sync!
      BatchProcess.process_priority_end_product_sync!(created_batch)
    rescue StandardError => error
      capture_exception(error: error)
    end
  end
end
