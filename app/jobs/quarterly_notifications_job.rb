# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :va_notify

  QUERY_LIMIT = ENV["QUARTERLY_NOTIFICATIONS_JOB_BATCH_SIZE"]

  NOTIFICATION_TYPES = Constants.QUARTERLY_STATUSES.to_h.tap do |types|
    types.delete(:quarterly_notification)
  end

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: SendNotificationJob queued to send_notification SQS queue
  def perform
    ensure_current_user_is_set

    begin
      NOTIFICATION_TYPES.each_key do |notification_type|
        AppealState.eligible_for_quarterly.send(notification_type)
          .find_in_batches(batch_size: QUERY_LIMIT.to_i) do |batch_of_appeal_states|
          batch_of_appeal_states.each do |appeal_state|
            NotificationInitializationJob.perform_later(
              appeal_id: appeal_state.appeal_id,
              appeal_type: appeal_state.appeal_type,
              template_name: "Quarterly Notification",
              appeal_status: notification_type.to_s
            )
          end
        end
      end
    rescue StandardError => error
      log_error(error)
    end
  end
end
