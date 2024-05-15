# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  include MessageConfigurations::DeleteMessageBeforeStart

  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = ENV["QUARTERLY_NOTIFICATIONS_JOB_BATCH_SIZE"]

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: SendNotificationJob queued to send_notification SQS queue
  def perform
    ensure_current_user_is_set

    AppealState.where(
      decision_mailed: false, appeal_cancelled: false
    ).find_in_batches(batch_size: QUERY_LIMIT.to_i) do |batched_appeal_states|
      batched_appeal_states.each do |appeal_state|
        status = appeal_state.quarterly_notification_status

        next unless status

        begin
          appeal = appeal_state.appeal
          MetricsService.record("Creating Quarterly Notification for #{appeal.class} ID #{appeal.id}",
                                name: "send_quarterly_notifications(appeal_state, appeal)") do
            AppellantNotification.notify_appellant(appeal, Constants.QUARTERLY_STATUSES.quarterly_notification, status)
          end
        rescue StandardError => error
          log_error(error, appeal_state.appeal_type, appeal_state.appeal_id)
        end
      end
    end
  end

  # Purpose: Log errors with the QuarterlyNotificationJob
  #
  # Params: none
  #
  # Response: none
  def log_error(error, appeal_type, appeal_id)
    Rails.logger.error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
            "#{appeal_type} ID #{appeal_id} because of #{error}")

    super(error)
  end
end
