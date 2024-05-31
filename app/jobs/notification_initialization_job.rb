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
  include IgnoreJobExecutionTime

  queue_as SendNotificationJob.queue_name_suffix
  application_attr :va_notify

  # ...
  #
  # @param appeal_id [Integer] Foreign key ID of the appeal to be associated with the notification.
  # @param appeal_type [String] Class name of appeal to be associated with the notification. Appeal or LegacyAppeal.
  # @param template_name [String] VANotify template name to be requested transmission of.
  #   Must be present in the configuration for our VANotify account, and must be a template represented in our
  #   notification_events table.
  # @param appeal_status [String] An optional status that is used to fill in a blank in the quarterly notification
  #   template to let the claimant know what the status of their appeal is.
  #
  # @return [SendNotificationJob, nil]
  #   A SendNotificationJob job object representing the job that was enqueued, or nil if a notification
  #   wasn't ultimately attempted to be sent.
  # :reek:LongParameterList
  def perform(appeal_id:, appeal_type:, template_name:, appeal_status: nil)
    begin
      ensure_current_user_is_set

      appeal = appeal_type.constantize.find_by(id: appeal_id)

      fail Caseflow::Error::AppealNotFound, "#{appeal_type} with ID #{appeal_id} could not be found." unless appeal

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
