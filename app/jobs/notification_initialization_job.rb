# frozen_string_literal: true

class NotificationInitializationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :va_notify

  def perform(appeal:, template_name:, appeal_status: nil)
    begin
      ensure_current_user_is_set

      AppellantNotification.notify_appellant(
        appeal,
        template_name,
        appeal_status
      )
    rescue StandardError => error
      Rails.logger.info(
        "Notification Init - VACOLS Connection at time of error: #{VACOLS::Record.connection_pool.stat}"
      )

      log_error(error)
    end
  end
end
