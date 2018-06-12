# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < CaseflowJob
  queue_as :low_priority

  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    RampElection.sync_all!

    reclosed_appeals = RampClosedAppeal.reclose_all!
    slack_service.send_notification("Reclosing RAMP VACOLS appeals TRACER (count: #{reclosed_appeals.count})")
  end
end
