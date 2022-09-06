# frozen_string_literal: true

class ReceiveNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_fakes? ? :receive_notifications : :"receive_notifications.fifo"
  application_attr :hearing_schedule

  def perform(message)
    if !message.nil?
      message_attributes = message[:message_attributes]
      if !message_attributes.nil?
        # load reference value to obtain notification id for record lookup
        notification_id = message_attributes[:reference][:string_value]

        # load intersecting fields that may change in our database
        email_address = message_attributes[:email_address][:string_value]
        phone_number = message_attributes[:phone_number][:string_value]
        status = message_attributes[:status][:string_value]
        type = message_attributes[:type][:string_value]

        # load record
        audit_record = Notification.find_by(id: notification_id)

        compare_notification_audit_record(audit_record, email_address, phone_number, status, type)

      else
        log_error("message_attributes was nil on the ReceiveNotificationListnerJob message. Existing Job.")
      end
    else
      log_error("There was no message passed into the ReceiveNotificationListener. Exiting job.")
    end
  end

  private

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

  # Purpose: Method to compare audit record from database with record in message
  #
  # Params:
  # - audit_record - audit record to compare with message
  # - email_address - email of recipient
  # - phone_number = phone number of recipient
  # - status - status of notification
  # - type - sms or email
  #
  # Returns: Updated model from update_audit_record
  def compare_notification_audit_record(audit_record, email_address, phone_number, status, type)
    if audit_record.email_address != email_address && !email_address.nil?
      audit.update!(email_address: email_address)
    end
    if audit_record.phone_number != phone_number && !phone_number.nil?
      audit.update!(phone_number: phone_number)
    end
    if audit_record.email_notification_status != status && !status.nil?
      audit.update!(email_notification_status: status)
    end
    if audit_record.notification_type != type && !type.nil?
      audit.update!(notification_type: type)
    end
    audit_record
  end
end
