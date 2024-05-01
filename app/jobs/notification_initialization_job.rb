# frozen_string_literal: true

class NotificationInitializationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :va_notify

  def perform(appeal:, template_name:, appeal_status: nil)
    begin
      ensure_current_user_is_set

      Rails.logger.info(
        "VACOLS Connection pool stats before initializing notification: #{VACOLS::Record.connection_pool.stat}"
      )

      AppellantNotification.notify_appellant(
        appeal,
        template_name,
        appeal_status
      )

      Rails.logger.info(
        "VACOLS Connection pool stats after initializing notification: #{VACOLS::Record.connection_pool.stat}"
      )
    rescue StandardError => error
      log_error(error)
    end
  end
end
