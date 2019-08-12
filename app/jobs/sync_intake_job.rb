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

    SlackService.new(msg: slack_message).send_notification
  end

  private

  def slack_message
    "Intake: Successfully reclosed #{reclosed_appeals.count} out of #{appeals_to_reclose.count} RAMP VACOLS appeals"
  end

  def reclosed_appeals
    appeals_to_reclose.each_with_object([]) do |appeal, result|
      appeal.reclose!
      result << appeal
    rescue StandardError => error
      # Rescue and capture errors so they don't cause the job to stop
      capture_exception(error: error, extra: { ramp_closed_appeal_id: appeal.id })
    end
  end

  def appeals_to_reclose
    @appeals_to_reclose ||= RampClosedAppeal.appeals_to_reclose
  end
end
