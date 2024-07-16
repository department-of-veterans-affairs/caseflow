# frozen_string_literal: true

# Purpose: Active Job that handles the processing of VA Notifcation event trigger.
# This job saves the data to an audit table and If the corresponding feature flag is enabled will send
# an email or SMS request to VA Notify API
# :reek:RepeatedConditional
class SendNotificationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include IgnoreJobExecutionTime

  queue_as { self.class.queue_name_suffix }
  application_attr :va_notify
  attr_accessor :notification_audit, :message

  class SendNotificationJobError < StandardError; end

  RETRY_ERRORS = [
    Caseflow::Error::VANotifyNotFoundError,
    Caseflow::Error::VANotifyInternalServerError,
    Caseflow::Error::VANotifyRateLimitError,
    HTTPClient::ReceiveTimeoutError
  ].freeze

  DISCARD_ERRORS = [
    Caseflow::Error::VANotifyUnauthorizedError,
    Caseflow::Error::VANotifyForbiddenError,
    SendNotificationJobError
  ].freeze

  RETRY_ERRORS.each do |err|
    retry_on(err, attempts: 5, wait: :exponentially_longer) do |job, exception|
      Rails.logger.error("Retrying #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
    end
  end

  DISCARD_ERRORS.each do |err|
    discard_on(err) do |job, exception|
      error_message = "Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}"
      err_level = exception.instance_of?(SendNotificationJobError) ? :error : :warn
      Rails.logger.send(err_level, error_message)
    end
  end

  class << self
    def queue_name_suffix
      :"send_notifications.fifo"
    end
  end

  # Must receive JSON string as argument
  def perform(message_json)
    ensure_current_user_is_set

    begin
      fail SendNotificationJobError, "Message argument of value nil supplied to job" if message_json.nil?

      @message = validate_message(JSON.parse(message_json, object_class: OpenStruct))

      ActiveRecord::Base.transaction do
        @notification_audit = find_or_create_notification_audit
        update_notification_statuses
        send_to_va_notify if message_status_valid?
      end
    rescue StandardError => error
      log_error(error)
      raise error
    end
  end

  private

  def event_type
    message.template_name
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
    appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(message.appeal_id)

    return appeal unless appeal.nil?

    fail SendNotificationJobError, "Associated appeal cannot be found for external ID #{message.appeal_id}"
  end

  # Purpose: Determine if either a quarterly sms notification or non-quarterly sms notification
  #
  # Returns: Boolean
  def sms_enabled?
    @sms_enabled ||= va_notify_sms_enabled? || va_notify_quarterly_sms_enabled?
  end

  def va_notify_sms_enabled?
    FeatureToggle.enabled?(:va_notify_sms) && !quarterly_notification?
  end

  def va_notify_quarterly_sms_enabled?
    FeatureToggle.enabled?(:va_notify_quarterly_sms) && quarterly_notification?
  end

  def quarterly_notification?
    event_type == Constants.EVENT_TYPE_FILTERS.quarterly_notification
  end

  # Purpose: Ensure necessary message attributes present to send notification
  #
  # Params: message: object containing details from appeal for notification
  #
  # Returns: message
  # :reek:FeatureEnvy
  def validate_message(message_to_validate)
    nil_attributes = [:appeal_id, :appeal_type, :template_name].filter { |attr| message_to_validate.send(attr).nil? }

    return message_to_validate unless nil_attributes.any?

    fail SendNotificationJobError, "Nil message attribute(s): #{nil_attributes.map(&:to_s).join(', ')}"
  end

  # Purpose: Find or create a new notification table row for the appeal
  #
  # Returns: Notification active model or nil
  def find_or_create_notification_audit
    params = {
      appeals_id: message.appeal_id,
      appeals_type: message.appeal_type,
      event_type: event_type,
      event_date: Time.zone.today,
      notification_type: notification_type,
      notifiable: appeal
    }

    if legacy_appeal_docketed_event? && FeatureToggle.enabled?(:appeal_docketed_event)
      notification = Notification.where(params).last

      return notification unless notification.nil?
    end

    create_notification(params.merge(participant_id: message.participant_id, notified_at: Time.zone.now))
  end

  # Purpose: Determine if the notification event is for a legacy appeal that has been docketed
  #
  # Returns: Boolean
  def legacy_appeal_docketed_event?
    event_type == Constants.EVENT_TYPE_FILTERS.appeal_docketed && appeal.is_a?(LegacyAppeal)
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
    params[:email_notification_status] = status
    params[:sms_notification_status] = status if sms_enabled?

    notification_audit.update(params)
  end

  # Purpose: Reformat message status if status belongs to invalid category
  #
  # Response: Message string
  def format_message_status
    return message.status if message_status_valid?

    case message.status
    when "No participant_id" then "No Participant Id Found"
    when "No claimant" then "No Claimant Found"
    when "Failure Due to Deceased" then "Failure Due to Deceased"
    else
      fail StandardError, "Message status #{message.status} is not recognized."
    end
  end

  # Purpose: Determine if message status belongs to invalid
  #
  # Response: Boolean
  def message_status_valid?
    ["No participant_id", "No claimant", "Failure Due to Deceased"].exclude?(message.status)
  end

  # Purpose: Send message to VA Notify to send notification
  #
  # Response: Updated Notification object
  def send_to_va_notify
    send_va_notify_email
    send_va_notify_sms if sms_enabled?
  end

  # Purpose: Build payload for VA Notify request body
  #
  # Response: Payload object
  def va_notify_payload
    {
      participant_id: message.participant_id,
      notification_id: notification_audit.id.to_s,
      first_name: first_name || "Appellant",
      docket_number: appeal.docket_number,
      status: message.appeal_status || ""
    }
  end

  # Purpose: Send payload to VA Notify to send email notification
  #
  # Response: Updated notification object
  def send_va_notify_email
    email_response = VANotifyService.send_email_notifications(
      va_notify_payload.merge(email_template_id: event.email_template_id)
    )

    if email_response.present?
      body = email_response.body
      notification_audit.update(
        notification_content: body["content"]["body"],
        email_notification_content: body["content"]["body"],
        email_notification_external_id: body["id"]
      )
    end
  end

  # Purpose: Send payload to VA Notify to send sms notification
  #
  # Response: Updated notification object
  def send_va_notify_sms
    response = VANotifyService.send_sms_notifications(va_notify_payload.merge(sms_template_id: event.sms_template_id))

    if response.present?
      notification_audit.update(
        sms_notification_content: response.body["content"]["body"],
        sms_notification_external_id: response.body["id"]
      )
    end
  end

  # Purpose: Determine notification type depending on enabled feature toggles and event type
  #
  # Response: String
  def notification_type
    if sms_enabled?
      "Email and SMS"
    else
      "Email"
    end
  end

  # Purpose: Parse first name of veteran or appellant from appeal
  #
  # Response: String
  def first_name
    appeal&.appellant_or_veteran_name&.split(" ")&.first
  end
end
