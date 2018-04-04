# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    # First sync the issues from all the known active RampElections
    # This will not sync issues from known inactive RampElections
    # nor from RampElections whose true status we dont know
    # (RampElections with end_product_status: nil)
    RampElection.active.map(&:recreate_issues_from_contentions!)

    # Now call sync_ep_status over all established claims
    # #sync_ep_status bails early on explicitly inactive elections
    RampElection.established.map(&:sync_ep_status!)
  end
end
