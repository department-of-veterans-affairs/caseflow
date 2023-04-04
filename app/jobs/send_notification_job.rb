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

  # Must receive JSON string as argument

  # rubocop:disable Layout/LineLength
  def perform(message_json)
    if message_json
      @va_notify_email = FeatureToggle.enabled?(:va_notify_email)
      @va_notify_sms = FeatureToggle.enabled?(:va_notify_sms)
      @va_notify_quarterly_sms = FeatureToggle.enabled?(:va_notify_quarterly_sms)
      message = JSON.parse(message_json, object_class: OpenStruct)
      if message.appeal_id && message.appeal_type && message.template_name
        notification_audit_record = create_notification_audit_record(
          message.appeal_id,
          message.appeal_type,
          message.template_name,
          message.participant_id
        )
        if notification_audit_record
          if message.status != "No participant_id" && message.status != "No claimant"
            to_update = {}
            if @va_notify_email
              to_update[:email_notification_status] = message.status
            end
            if @va_notify_sms && message.template_name != "Quarterly Notification" ||
               @va_notify_quarterly_sms && message.template_name == "Quarterly Notification"
              to_update[:sms_notification_status] = message.status
            end
            update_notification_audit_record(notification_audit_record, to_update)
            if message.template_name == "Appeal docketed" && message.appeal_type == "LegacyAppeal" && !FeatureToggle.enabled?(:appeal_docketed_notification)
              notification_audit_record.update!(email_enabled: false)
            else send_to_va_notify(message, notification_audit_record)
            end
          else
            status = (message.status == "No participant_id") ? "No Participant Id Found" : "No Claimant Found"
            to_update = {}
            if @va_notify_email
              to_update[:email_notification_status] = status
            end
            if @va_notify_sms && message.template_name != "Quarterly Notification" ||
               @va_notify_quarterly_sms && message.template_name == "Quarterly Notification"
              to_update[:sms_notification_status] = status
            end
            update_notification_audit_record(notification_audit_record, to_update)
          end
          notification_audit_record.save!
        else
          log_error("Audit record was unable to be found or created in SendNotificationListnerJob. Exiting Job.")
        end
      else
        log_error("appeals_id or appeal_type or event_type was nil in the SendNotificationListnerJob. Exiting job.")
      end
    else
      log_error("There was no message passed into the SendNotificationListener.perform_later function. Exiting job.")
    end
  end
  # rubocop:enable Layout/LineLength

  private

  # Purpose: Updates and saves notification status for notification_audit_record
  #
  # Params: notification_audit_record: object,
  #         to_update: hash. key corresponds to notification_events column and value corresponds to new value
  #
  # Response: Updated notification_audit_record
  def update_notification_audit_record(notification_audit_record, to_update)
    to_update.each do |key, value|
      notification_audit_record[key] = value
    end
  end

  # Purpose: Send message to VA Notify to send notification
  #
  # Params: message (object containing participant_id, template_name, and others) Details from appeal for notification
  #         notification_id: ID of the notification_audit record (must be converted to string to work with API)
  #
  # Response: Updated Notification object (still not saved)
  def send_to_va_notify(message, notification_audit_record)
    event = NotificationEvent.find_by(event_type: message.template_name)
    email_template_id = event.email_template_id
    sms_template_id = event.sms_template_id
    quarterly_sms_template_id = NotificationEvent.find_by(event_type: "Quarterly Notification").sms_template_id
    appeal = Appeal.find_by_uuid(message.appeal_id) || LegacyAppeal.find_by(vacols_id: message.appeal_id)
    first_name = appeal&.appellant_or_veteran_name&.split(" ")&.first || "Appellant"
    status = message.appeal_status || ""
    docket_number = appeal.docket_number

    if @va_notify_email
      response = VANotifyService.send_email_notifications(
        message.participant_id,
        notification_audit_record.id.to_s,
        email_template_id,
        first_name,
        docket_number,
        status
      )
      if !response.nil? && response != ""
        to_update = { notification_content: response.body["content"]["body"],
                      email_notification_content: response.body["content"]["body"],
                      email_notification_external_id: response.body["id"] }
        update_notification_audit_record(notification_audit_record, to_update)
      end
    end

    if @va_notify_sms && sms_template_id != quarterly_sms_template_id ||
       @va_notify_quarterly_sms && sms_template_id == quarterly_sms_template_id
      response = VANotifyService.send_sms_notifications(
        message.participant_id,
        notification_audit_record.id.to_s,
        sms_template_id,
        first_name,
        docket_number,
        status
      )
      if !response.nil? && response != ""
        to_update = {
          sms_notification_content: response.body["content"]["body"], sms_notification_external_id: response.body["id"]
        }
        update_notification_audit_record(notification_audit_record, to_update)
      end
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
  # - appeals_id - UUID or vacols_id of the appeals the event triggered
  # - appeals_type - Polymorphic column to identify the type of appeal
  # - - Appeal
  # - - LegacyAppeal
  # - event_type: Name of the event that has transpired. Event names can be found in the notification_events table
  #
  # Returns: Notification active model or nil

  # rubocop:disable all
  def create_notification_audit_record(appeals_id, appeals_type, event_type, participant_id)
    notification_type =
      if @va_notify_email && @va_notify_sms && event_type != "Quarterly Notification" ||
         @va_notify_email && @va_notify_quarterly_sms && event_type == "Quarterly Notification"
        "Email and SMS"
      elsif @va_notify_email
        "Email"
      elsif @va_notify_sms && event_type != "Quarterly Notification" ||
            @va_notify_quarterly_sms && event_type == "Quarterly Notification"
        "SMS"
      else
        "None"
      end

    if event_type == "Appeal docketed" && appeals_type == "LegacyAppeal" && FeatureToggle.enabled?(:appeal_docketed_event)
      notification = Notification.where(appeals_id: appeals_id, event_type: event_type, notification_type: notification_type, appeals_type: appeals_type, event_date: Time.zone.today).last
      if !notification.nil?
        notification
      else
        Notification.new(
          appeals_id: appeals_id,
          appeals_type: appeals_type,
          event_type: event_type,
          notification_type: notification_type,
          participant_id: participant_id,
          notified_at: Time.zone.now,
          event_date: Time.zone.today
        )
      end
    else
      Notification.new(
        appeals_id: appeals_id,
        appeals_type: appeals_type,
        event_type: event_type,
        notification_type: notification_type,
        participant_id: participant_id,
        notified_at: Time.zone.now,
        event_date: Time.zone.today
      )
    end
  end
  # rubocop:enable all
end
