# frozen_string_literal: true

# Purpose: Active Job that handles the processing of VA Notifcation event trigger.
# This job saves the data to an audit table and If the corresponding feature flag is enabled will send
# an email or SMS request to VA Notify API
class SendNotificationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"
  application_attr :hearing_schedule

  class SendNotificationJobError < StandardError; end

  RETRY_ERRORS = [
    Caseflow::Error::VANotifyNotFoundError,
    Caseflow::Error::VANotifyInternalServerError,
    Caseflow::Error::VANotifyRateLimitError
  ].freeze

  DISCARD_ERRORS = [
    Caseflow::Error::VANotifyUnauthorizedError,
    Caseflow::Error::VANotifyForbiddenError,
    SendNotificationJobError
  ].freeze

  RETRY_ERRORS.each do |err|
    retry_on(err, attempts: 10, wait: :exponentially_longer) do |job, exception|
      Rails.logger.error("Retrying #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
    end
  end

  DISCARD_ERRORS.each do |err|
    discard_on(err) do |job, exception|
      message = "Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}"
      err_level = exception.instance_of?(SendNotificationJobError) ? :error : :warn
      Rails.logger.send(err_level, message)
    end
  end

  # Must receive JSON string as argument

  def perform(message_json)
    ensure_current_user_is_set

    fail SendNotificationJobError, "Message argument of value nil supplied to job" if message_json.nil?

    @message = validate_message(JSON.parse(message_json, object_class: OpenStruct))

    ActiveRecord::Base.transaction do
      @notification_audit = find_or_create_notification_audit
      update_notification_statuses
      maybe_send_to_va_notify if message_status_valid?
    end
  end

  private

  def event_type
    @message.template_name
  end

  def event
    @event ||= NotificationEvent.find_by(event_type: event_type)
  end

  def appeal
    @appeal ||= find_appeal_by_external_id
  end

  # Purpose: Find appeal by external ID
  #
  # Returns: Appeal object
  def find_appeal_by_external_id
    appeal = Appeal.find_by_uuid(@message.appeal_id) || LegacyAppeal.find_by_vacols_id(@message.appeal_id)

    return appeal unless appeal.nil?

    fail SendNotificationJobError, "Associated appeal cannot be found"
  end

  # Purpose: Determine if either a quarterly sms notification or non-quarterly sms notification
  #
  # Returns: Boolean
  def sms_enabled
    @sms_enabled ||= va_notify_sms_enabled? || va_notify_quarterly_sms_enabled?
  end

  def va_notify_sms_enabled?
    FeatureToggle.enabled?(:va_notify_sms) && !quarterly_notification?
  end

  def va_notify_quarterly_sms_enabled?
    FeatureToggle.enabled?(:va_notify_quarterly_sms) && quarterly_notification?
  end

  def quarterly_notification?
    event_type == "Quarterly Notification"
  end

  # Purpose: Determine if email notifications enabled
  #
  # Returns: Boolean
  def email_enabled
    @email_enabled ||= FeatureToggle.enabled?(:va_notify_email)
  end

  # Purpose: Ensure necessary message attributes present to send notification
  #
  # Params: messag: object containing details from appeal for notification
  #
  # Returns: message
  def validate_message(message)
    nil_attributes = [:appeal_id, :appeal_type, :template_name].filter { |attr| message.send(attr).nil? }

    return message unless nil_attributes.any?

    fail SendNotificationJobError, "Nil message attribute(s): #{nil_attributes.map(&:to_s).join(', ')}"
  end

  # Purpose: Find or create a new notification table row for the appeal
  #
  # Returns: Notification active model or nil
  def find_or_create_notification_audit
    params = {
      appeals_id: @message.appeal_id,
      appeals_type: @message.appeal_type,
      event_type: event_type,
      event_date: Time.zone.today,
      notification_type: notification_type
    }

    if legacy_appeal_docketed_event? && FeatureToggle.enabled?(:appeal_docketed_event)
      notification = Notification.where(params).last

      return notification unless notification.nil?
    end

    create_notification(params.merge(participant_id: @message.participant_id, notified_at: Time.zone.now))
  end

  # Purpose: Determine if the notification event is for a legacy appeal that has been docketed
  #
  # Returns: Boolean
  def legacy_appeal_docketed_event?
    event_type == "Appeal docketed" && appeal.is_a?(LegacyAppeal)
  end

  # Purpose: Create notification audit record
  #
  # Params: params: Payload of attributes with which to create notification object
  #
  # Returns: Notification object
  def create_notification(params)
    notification = Notification.create(params)

    return notification unless notification.nil?

    fail SendNotificationJobError, "Notification audit record was unable to be found or created"
  end

  # Purpose: Updates and saves notification status for notification object
  #
  # Response: Updated notification object
  def update_notification_statuses
    status = format_message_status
    params = {}
    params[:email_notification_status] = status if email_enabled
    params[:sms_notification_status] = status if sms_enabled

    @notification_audit.update(params)
  end

  # Purpose: Reformat message status if status belongs to invalid category
  #
  # Response: Message string
  def format_message_status
    return @message.status if message_status_valid?

    (@message.status == "No participant_id") ? "No Participant Id Found" : "No Claimant Found"
  end

  # Purpose: Determine if message status belongs to invalid
  #
  # Response: Boolean
  def message_status_valid?
    ["No participant_id", "No claimant"].exclude?(@message.status)
  end

  # Purpose: Send message to VA Notify unless certain feature toggles are disabled
  #
  # Response: Updated notification object
  def maybe_send_to_va_notify
    if legacy_appeal_docketed_and_notifications_disabled?
      @notification_audit.update(email_enabled: false)
    else
      send_to_va_notify
    end
  end

  # Purpose: Determine whether notification should be sent for legacy docketed appeal
  #
  # Response: Boolean
  def legacy_appeal_docketed_and_notifications_disabled?
    legacy_appeal_docketed_event? && !FeatureToggle.enabled?(:appeal_docketed_notification)
  end

  # Purpose: Send message to VA Notify to send notification
  #
  # Response: Updated Notification object
  def send_to_va_notify
    send_va_notify_email if email_enabled
    send_va_notify_sms if sms_enabled
  end

  # Purpose: Build payload for VA Notify request body
  #
  # Response: Payload object
  def va_notify_payload
    {
      participant_id: @message.participant_id,
      notification_id: @notification_audit.id.to_s,
      first_name: first_name || "Appellant",
      docket_number: appeal.docket_number,
      status: @message.appeal_status || ""
    }
  end

  # Purpose: Send payload to VA Notify to send email notification
  #
  # Response: Updated notification object
  def send_va_notify_email
    response = VANotifyService.send_email_notifications(
      va_notify_payload.merge(email_template_id: event.email_template_id)
    )

    if response.present?
      @notification_audit.update(
        notification_content: response.body["content"]["body"],
        email_notification_content: response.body["content"]["body"],
        email_notification_external_id: response.body["id"]
      )
    end
  end

  # Purpose: Send payload to VA Notify to send sms notification
  #
  # Response: Updated notification object
  def send_va_notify_sms
    response = VANotifyService.send_sms_notifications(va_notify_payload.merge(sms_template_id: event.sms_template_id))

    if response.present?
      @notification_audit.update(
        sms_notification_content: response.body["content"]["body"],
        sms_notification_external_id: response.body["id"]
      )
    end
  end

  # Purpose: Determine notification type depending on enabled feature toggles and event type
  #
  # Response: String
  def notification_type
    if email_enabled
      sms_enabled ? "Email and SMS" : "Email"
    elsif sms_enabled
      "SMS"
    else
      "None"
    end
  end

  # Purpose: Parse first name of veteran or appellant from appeal
  #
  # Response: String
  def first_name
    appeal&.appellant_or_veteran_name&.split(" ")&.first
  end
end
