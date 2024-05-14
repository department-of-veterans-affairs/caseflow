# frozen_string_literal: true

class NotificationInitializationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_as SendNotificationJob.queue_name_suffix
  application_attr :va_notify

  def perform(appeal_id:, appeal_type:, template_name:, appeal_status: nil)
    begin
      ensure_current_user_is_set

      appeal = appeal_type.constantize.find(appeal_id)

      fail StandardError, "#{appeal_type} with ID #{appeal_id} could not be found." unless appeal

      AppellantNotification.notify_appellant(
        appeal,
        template_name,
        appeal_status
      )
    rescue StandardError => error
      log_error(error)
    end
  end
end
