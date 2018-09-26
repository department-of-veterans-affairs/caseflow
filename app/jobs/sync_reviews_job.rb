# This job will sync end products & contentions that we created for AMA reviews
class SyncReviewsJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  DEFAULT_EP_LIMIT = 100

  def perform(args = {})
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    # specified limit of end products that will be synced
    limit = args["limit"] || DEFAULT_EP_LIMIT

    EndProductEstablishment.order_by_sync_priority.limit(limit).each do |end_product_establishment|
      EndProductSyncJob.perform_later(end_product_establishment.id)
    end

    RampRefiling.need_to_reprocess.each do |ramp_refiling|
      begin
        ramp_refiling.create_end_product_and_contentions!
      rescue StandardError => e
        # Rescue and capture errors so they don't cause the job to stop
        Raven.capture_exception(e)
      end
    end

    [HigherLevelReview, SupplementalClaim].each do |klass|
      klass.requires_processing.limit(limit).each do |claim_review|
        ClaimReviewProcessJob.perform_later(claim_review)
      end
    end
  end
end
