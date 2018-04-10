# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < ApplicationJob
  queue_as :low_priority

  def perform
    RampElection.active.each do |ramp_election|
      # Set user to system_user to avoid sensitivity errors
      RequestStore.store[:current_user] = User.system_user

      begin
        ramp_election.recreate_issues_from_contentions!
        ramp_election.sync_ep_status!
      rescue ActiveRecord::RecordInvalid
        Rails.logger.error "SyncIntakeJob failed for #{e.message}"
        Raven.capture_exception(e)
      end

      # Sleep for 1 second to avoid tripping BGS alerts
      sleep 1
    end
  end
end
