# This job will sync end products & contentions that we created for AMA reviews
class SyncReviewsJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  DEFAULT_EP_LIMIT = 100

  def perform(args = {})
    RequestStore.store[:application] = "intake"

    # specified limit of end products that will be synced
    limit = args["limit"] || DEFAULT_EP_LIMIT

    EndProductEstablishment.order_by_sync_priority.limit(limit).each do |end_product_establishment|
      EndProductSyncJob.perform_later(end_product_establishment.id)
    end
  end
end
