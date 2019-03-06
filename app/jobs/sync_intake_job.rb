# frozen_string_literal: true

# This job will fetch the number of contentions for every
# EP known to Intake
class SyncIntakeJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    Intake.close_expired_intakes!

    appeals_to_reclose = RampClosedAppeal.appeals_to_reclose
    reclosed_appeals = []
    appeals_to_reclose.each do |appeal|
      appeal.reclose!
      reclosed_appeals << appeal
    rescue StandardError => e
      # Rescue and capture errors so they don't cause the job to stop
      Raven.capture_exception(e, extra: { ramp_closed_appeal_id: appeal.id })
    end
    slack_service.send_notification(
      "Intake: Successfully reclosed #{reclosed_appeals.count} out of #{appeals_to_reclose.count} RAMP VACOLS appeals"
    )
  end
end
