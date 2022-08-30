# frozen_string_literal: true

class ReceiveNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_fakes? ? :receive_notifications : :"receive_notifications.fifo"
  application_attr :hearing_schedule

  def perform(message)
    RequestStore.store[:current_user] = User.system_user
    # call to VANotify to obtain status, check if status is same as our record in database, update if necessary
    send_to_va_notify(message)
  end

  # Send message to VA Notify Service API to retreive status
  def send_to_va_notify(message)
    message_attributes = message[:message_attributes]
    appeal_id = message_attributes[:appeal_id][:string_value]
    notification = Notification.find_by(appeal_id: appeal_id)
    notification_id = notification.nil? ? "" : notification.id
    response = VANotifyService.get_status(notification_id)

    # Fake VANotify Error Handling
    if response.code >= 400
      Rails.logger.error("Failed with error: #{response.body['error']} - #{response.body['message']} ")
      return response.body
    end

    # TODO: If status changed, then update record
  end
end
