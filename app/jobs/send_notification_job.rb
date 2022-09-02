# frozen_string_literal: true

# Purpose: Active Job that handles the processing of VA Notifcation event trigger. 
# This job saves the data to an audit table and If the corresponding feature flag is enabled will send
# an email or SMS request to VA Notify API
class SendNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::VANotifyNotFoundError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("Retrying #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  retry_on(Caseflow::Error::VANotifyInternalServerError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("Retrying #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  retry_on(Caseflow::Error::VANotifyRateLimitError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("Retrying #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  discard_on(Caseflow::Error::VANotifyUnauthorizedError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  discard_on(Caseflow::Error::VANotifyForbiddenError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  # Must receive JSON as argument
  def perform(message)
    if !message.nil?
      # message_attributes = message[:message_attributes]
      # if [appeals_id, appeals_type, appeals_status, event_type].none?(&:nil?)
        # {|a| a.nil?}
        appeals_id = message["appeal_id"]
        appeals_type = message["appeal_type"]
        appeals_status = message["status"] || ""
        event_type = message["template_name"]

        if !appeals_id.nil? && !appeals_type.nil? && !event_type.nil? # [appeals_id, appeals_type, appeals_status, event_type].none?(&:nil?)
          notification_audit_record = create_notification_audit_record(appeals_id, appeals_type, event_type)
          if !notification_audit_record.nil?
            if appeals_status != "No participant_id" && appeals_status != "No claimant"
              status = appeals_status
              notification_audit_record.email_notification_status = status
              notification_audit_record.sms_notification_status = status
              notification_audit_record.save!
              # send_to_va_notify(message_attributes, appeals_id, appeals_status)
            else
              status = (appeals_status == "No particpant_id") ? "No Participant Id Found" : "No Claimant Found"
              notification_audit_record.email_notification_status = status
              notification_audit_record.sms_notification_status = status
              notification_audit_record.save!
            end
          else
            log_error("Audit record was unable to be found or created in SendNotificationListnerJob. Exiting Job.")
          end
        else
          log_error("appeals_id or appeal_type or event_type was nil in the SendNotificationListnerJob. Exiting job.")
        end
      # else
      #   log_error("message_attributes was nil on the SendNotificationListnerJob message. Exiting Job.")
      # end
    else
      log_error("There was no message passed into the SendNotificationListener.perform_later function. Exiting job.")
    end
  end

  private

  # Send message to VA Notify to send notification
  def send_to_va_notify(message_attributes, appeal_id, appeal_status)
    if FeatureToggle.enabled?(:va_notify_email)

    end

    if FeatureToggle.enabled?(:va_notify_sms)

    end
  end

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

  # Purpose: Method to create a new notification table row for the appeal
  #
  # Params:
  # - appeals_id - UUID or Vacols id of the appeals the event triggered
  # - appeals_type - Polynorphic column to identify the type of appeal
  # - - Appeal
  # - - LegacyAppeal
  # - event_type: Name of the event that has transpired. Event names can be found in the notification_events table
  #
  # Returns: Noticiation active model or nil
  def create_notification_audit_record(appeals_id, appeals_type, event_type)
    notification_type = "Email"
    Notification.create(
      appeals_id: appeals_id,
      appeals_type: appeals_type,
      event_type: event_type,
      notification_type: notification_type,
      notified_at: Time.zone.now,
      event_date: Time.zone.today
    )
  end
end
