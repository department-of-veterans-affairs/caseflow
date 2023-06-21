


class BatchAndProcessPriorityEndProductSyncJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue

  def preform
    BatchProcess::batch_priority_end_product_sync
    BatchProcess::process_priority_end_product_sync
  end
end
