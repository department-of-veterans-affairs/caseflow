
# frozen_string_literal: true

class SendNotificationJob < CaseflowJob
  queue_as :send_notifications
  application_attr :hearing_schedule

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
    Notification.create!(audit)
  end
  # rubocop:enable Style/BracesAroundHashParameters

  def send_to_va_notify(result)
    message = result.messages.first
    email_address = ""
    event = NotificationEvent.find_by(event_type: message.message_attributes["template_name"]["string_value"])
    email_template_id = event.email_template_id
    sms_template_id = event.sms_template_id
    phone_number = ""
    status = message.message_attributes["status"]["string_value"]
    phone_number = nil if phone_number.empty?
    response = VANotifyService.send_notifications(email_address, email_template_id, phone_number, sms_template_id, status)
    audit_params(message, response)
  end

  def audit_params(message, response)
    message_attributes = message.message_attributes
    {
      appeals_id: message_attributes["appeal_id"]["string_value"],
      appeals_type: message_attributes["appeal_type"]["string_value"],
      event_type: message_attributes["template_name"]["string_value"],
      participant_id: message_attributes["participant_id"]["string_value"],
      notification_type: message_attributes["template_name"]["string_value"],
      recipient_email: "",
      recipient_phone_number: "",
      notified_at: Time.at(message["attributes"]["SentTimestamp"].to_i),
      notification_content: response.body["content"]["body"],
      event_date: Time.zone.today,
      email_notification_status: "sent",
      sms_notification_status: "sent"
    }
  end
end