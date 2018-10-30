# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    Intake.close_expired_intakes!
    reclosed_appeals = RampClosedAppeal.reclose_all!
    slack_service.send_notification("Intake: Reclosed RAMP VACOLS appeals (count: #{reclosed_appeals.count})")
  end
end
