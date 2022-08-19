# frozen_string_literal: true

class SendNotificationJob < CaseflowJob
  queue_as :send_notifications
  application_attr :hearing_schedule

  def perform
    RequestStore.store[:current_user] = User.system_user
    queue_name = "caseflow_development_send_notifications"
    queue_url = Shoryuken::Client.sqs.get_queue_url(queue_name: queue_name).queue_url
    # rubocop:disable Style/BracesAroundHashParameters
    receive_message_result = Shoryuken::Client.sqs.receive_message(
      {
        queue_url: queue_url,
        message_attribute_names: ["All"],
        max_number_of_messages: 10,
        wait_time_seconds: 20,
        visibility_timeout: 5
      }
    )
    puts receive_message_result
    send_to_va_notify_and_delete(receive_message_result, queue_url)
  end

  def send_to_va_notify_and_delete(result, queue_url)
    result.messages.each do |message|
      email_address = message.message_attributes["email_address"]["string_value"]
      email_template_id = message.message_attributes["email_template_id"]["string_value"]
      phone_number = message.message_attributes["phone_number"]["string_value"]
      sms_template_id = message.message_attributes["sms_template_id"]["string_value"]
      status = message.message_attributes["status"]["string_value"]
      phone_number = nil if phone_number.empty?

      Shoryuken::Client.sqs.delete_message({ queue_url: queue_url, receipt_handle: message.receipt_handle })
      # rubocop:enable Style/BracesAroundHashParameters

      VANotifyService.send_notifications(email_address, email_template_id, phone_number, sms_template_id, status)
    end
  end
end