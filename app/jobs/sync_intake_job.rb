# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ApplicationJob
  queue_as :low_priority

  def perform
    RampElection.active.each do |ramp_election|
      # Set user to user who established to avoid sensitivity errors
      # TODO: not all RampElections will have an Intake
      # so we may need to figure out a default user
      RequestStore.store[:current_user] = ramp_election.successful_intake.user if ramp_election.successful_intake

      ramp_election.recreate_issues_from_contentions!
      ramp_election.sync_ep_status!

      # Sleep for 1 second to avoid tripping BGS alerts
      sleep 1

      # TODO: need a rescue here for sensitivity errors
    end
  end
end
