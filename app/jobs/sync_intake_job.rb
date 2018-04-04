# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    RampElection.active.map do |ramp_election|
        # Set user to user who established to avoid sensitivity errors
        intake = RampElectionIntake
            .where(detail_id: ramp_election.id, completion_status: "success")
            .order(:completed_at)
            .last
        return unless intake
        user = intake.user
        RequestStore.store[:current_user] = user
        ramp_election.recreate_issues_from_contentions!
        ramp_election.sync_ep_status!

        # Sleep for 1 second to avoid tripping BGS alerts
        sleep 1
    end
  end
end
