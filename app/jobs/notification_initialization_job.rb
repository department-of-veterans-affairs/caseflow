# frozen_string_literal: true

# == Overview
#
# The NotificationInitializationJob encapsulates the instantiation of templates
# for messages to be sent by VANotify.
#
# Information such as whether or not the claimant is deceased and if the veteran is still the
#   primary claimant (or if an appellant substitution has taken place) is gathered and factored
#   into what is then sent to the SendNotificationJob.
#
# This job was created in order to extract logic that causes calls to external services so that
#   large batch notification queueing jobs, like the QuarterlyNotificationsJob, can run much more quickly.
class NotificationInitializationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_as SendNotificationJob.queue_name_suffix
  application_attr :va_notify

  def perform(appeal_id:, appeal_type:, template_name:, appeal_status: nil)
    begin
      ensure_current_user_is_set

      appeal = appeal_type.constantize.find_by(id: appeal_id)

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
