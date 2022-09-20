# frozen_string_literal: true

class VANotifyStatusUpdateJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = "650"#{ENV["VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT"]

  def perform
    notifications_not_processed.each do |notification|
      sms_external_id = notification.sms_notification_external_id
      email_external_id = notification.email_notification_external_id
      case notification.notification_type
      when "Email"
        update_attributes = get_current_status(email_external_id, "Email")
        update_notification_audit_record(notification, update_attributes)
      when "SMS"
        update_attributes = get_current_status(sms_external_id)
        update_notification_audit_record(notification, update_attributes, "SMS")
      when "Email and SMS"
        update_attributes = get_current_status(email_external_id, "Email")
        update_notification_audit_record(notification, update_attributes)
        update_attributes = get_current_status(sms_external_id, "SMS")
        update_notification_audit_record(notification, update_attributes)
      end
      notification.save!
    end
  end

  private

  def notifications_not_processed
    find_notifications_not_processed.first(QUERY_LIMIT.to_i)
  end

  def find_notifications_not_processed
    Notification.where("(notification_type = 'Email' AND email_notification_status = 'Success') \
      OR (notification_type = 'SMS' AND sms_notification_status = 'Success') \
      OR (notification_type = 'Email and SMS' AND \
         (sms_notification_status = 'Success' OR email_notification_status = 'Success'))")
  end

  def log_error(message)
    Rails.logger.error(message)
  end

  def log_info(message)
    Rails.logger.info(message)
  end

  def get_current_status(notification_id, type)
    response = VANotifyService.get_status(notification_id)
    if response.code == 200
      response_data = response.raw_body
      if type == "Email"
        { "email_notification_status" => response_data.status, "recipient_email" => response_data.email_address }
      elsif type == "SMS"
        { "sms_notification_status" => response_data.status, "recipient_phone_number" => response_data.phone_number }
      end
    else
      log_error("VA Notify APi returned error for notification " + notification_id)
      nil
    end
  end

  def update_notification_audit_record(notification_audit_record, to_update)
    to_update&.each do |key, value|
      notification_audit_record[key] = value
    end
  end
end
