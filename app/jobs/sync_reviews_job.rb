# This job will sync end products & contentions that we created for AMA reviews
class SyncReviewsJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  DEFAULT_EP_LIMIT = 50

  def perform(args = {})
    RequestStore.store[:application] = "intake"

    # specified limit of end products that will be synced
    limit = args["limit"] || DEFAULT_EP_LIMIT

    RampElection.order_by_sync_priority.limit(limit).each do |ramp_election|
      RampElectionSyncJob.perform_later(ramp_election.id)
    end
  end
end
