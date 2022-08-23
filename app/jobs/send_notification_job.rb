
# frozen_string_literal: true

class SendNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::VANotifyNotFoundError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  retry_on(Caseflow::Error::VANotifyApiError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  retry_on(Caseflow::Error::VANotifyRateLimitError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  discard_on(Caseflow::Error::VANotifyUnauthorizedError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  discard_on(Caseflow::Error::VANotifyForbiddenError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id}) because failed with error: #{exception}")
  end

  # rubocop:disable Style/BracesAroundHashParameters
  def perform
    RequestStore.store[:current_user] = User.system_user
    queue_url = Shoryuken::Client.sqs.get_queue_url(queue_name: queue_name).queue_url
    receive_message_result = Shoryuken::Client.sqs.receive_message(
      {
        queue_url: queue_url,
        message_attribute_names: ["All"],
        max_number_of_messages: 1,
        wait_time_seconds: 20,
        visibility_timeout: 5
      }
    )
    message_list = receive_message_result.messages
    fail Caseflow::Error::EmptyQueueError, "There are no messages in queue yet" if message_list.empty?

    audit = send_to_va_notify(receive_message_result)
    Shoryuken::Client.sqs.delete_message({ queue_url: queue_url, receipt_handle: message_list.first.receipt_handle })
    Notification.create!(audit) unless audit["error"]
  end
  # rubocop:enable Style/BracesAroundHashParameters

  def send_to_va_notify(result)
    message = result.messages.first
    # email_address = ""
    event = NotificationEvent.find_by(event_type: message.message_attributes["template_name"]["string_value"])
    email_template_id = event.email_template_id
    sms_template_id = event.sms_template_id
    notification_events_id = event.id
    notification_type = "Email/Text"
    response = VANotifyService.send_notifications(participant_id, email_template_id, phone_number, sms_template_id)
    # Fake VANotify Error Handling
    return response.body if response.code >= 400

    audit_params(message, response, notification_events_id, notification_type)
  end

  def audit_params(message, response, notification_events_id, notification_type)
    message_attributes = message.message_attributes
    {
      appeals_id: message_attributes["appeal_id"]["string_value"],
      appeals_type: message_attributes["appeal_type"]["string_value"],
      notification_events_id: notification_events_id,
      event_type: message_attributes["template_name"]["string_value"],
      participant_id: message_attributes["participant_id"]["string_value"],
      notification_type: notification_type,
      recipient_email: "",
      recipient_phone_number: "",
      notified_at: Time.zone.at(message["attributes"]["SentTimestamp"].to_i),
      notification_content: response.body["content"]["body"],
      event_date: Time.zone.today,
      email_notification_status: message_attributes["status"]["string_value"],
      sms_notification_status: (notification_type == "Email/Text") ? message_attributes["status"]["string_value"] : ""
    }
  end
end