# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    # First sync the issues
    RampElection.active.map(&:recreate_issues_from_contentions!)

    # Then sync the EP statuses
    RampElection.established.map(&:sync_ep_status!)
  end
end
