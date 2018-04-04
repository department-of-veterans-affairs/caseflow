# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    RampElection.active.each do |ramp_election|
        # Set user to user who established to avoid sensitivity errors
        intake = RampElectionIntake
            .where(detail_id: ramp_election.id, completion_status: "success")
            .order(:completed_at)
            .last

        RequestStore.store[:current_user] = intake.user if intake

        ramp_election.recreate_issues_from_contentions!
        ramp_election.sync_ep_status!

        # Sleep for 1 second to avoid tripping BGS alerts
        sleep 1
    end
  end
end
