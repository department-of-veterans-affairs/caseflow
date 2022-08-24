# frozen_string_literal: true

class SendNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"
  application_attr :hearing_schedule

  retry_on(Caseflow::Error::VANotifyNotFoundError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  retry_on(Caseflow::Error::VANotifyInternalServerError, attempts: 10, wait: :exponentially_longer) do |job, exception|
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

  def perform(message)
    RequestStore.store[:current_user] = User.system_user
    audit = send_to_va_notify(message)
    Notification.create!(audit) unless audit["error"]
  end

  # Send message to VA Notify to send notification
  def send_to_va_notify(message)
    message_attributes = message[:message_attributes]
    participant_id = message_attributes[:participant_id][:string_value]
    event = NotificationEvent.find_by(event_type: message_attributes[:template_name][:string_value])
    email_template_id = event.nil? ? "" : event.email_template_id
    notification_events_id = event.nil? ? "" : event.id
    notification_type = "Email"
    appeal_id = message_attributes[:appeal_id][:string_value]
    appeal_status = message_attributes[:appeal_status] ? message_attributes[:appeal_status][:string_value] : ""
    response = VANotifyService.send_notifications(participant_id, appeal_id, email_template_id, appeal_status)

    # Fake VANotify Error Handling
    if response.code >= 400
      Rails.logger.error("Failed with error: #{response.body['error']} - #{response.body['message']} ")
      return response.body
    end

    audit_params(message, response, notification_events_id, notification_type)
  end

  # Create parameters for creating a notification record in the db
  def audit_params(message, response, notification_events_id, notification_type)
    message_attributes = message[:message_attributes]
    status = VANotifyService.get_status(response.body["id"]).body
    {
      appeals_id: message_attributes[:appeal_id][:string_value],
      appeals_type: message_attributes[:appeal_type][:string_value],
      notification_events_id: notification_events_id,
      event_type: message_attributes[:template_name][:string_value],
      participant_id: message_attributes[:participant_id][:string_value],
      notification_type: notification_type,
      recipient_email: status["email_address"],
      recipient_phone_number: status["phone_number"],
      notified_at: status["sent_at"],
      notification_content: response.body["content"]["body"],
      event_date: Time.zone.today,
      email_notification_status: status["status"],
      sms_notification_status: (notification_type == "Email/Text") ? status["status"] : ""
    }
  end
end
